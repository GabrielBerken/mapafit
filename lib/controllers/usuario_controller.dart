import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapafit/models/usuario_model.dart';
import 'package:mapafit/services/api_service.dart';

/// Realiza o login do usuário
Future<Usuario> login(String email, String senha) async {
  try {
    final response = await ApiService().post(
      '/usuarios/login',
      body: {
        'email': email,
        'senha': senha,
      },
    );

    // Handle different response formats
    Map<String, dynamic> userJson;
    if (response['usuario'] != null) {
      userJson = response['usuario'];
    } else if (response['user'] != null) {
      userJson = response['user'];
    } else {
      userJson = Map<String, dynamic>.from(response);
    }
    
    // Ensure token is set from the right location
    final token = response['token'] ?? userJson['token'];
    if (token == null) {
      throw Exception('No authentication token received');
    }
    
    // Create user object
    final user = Usuario.fromJson(userJson);
    
    // Save token and user ID to ApiService
    await ApiService().saveToken(token);
    await ApiService().setCurrentUserId(user.id);

    // Cache the current user's ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.id);

    return user;
  } catch (e) {
    throw Exception('Erro durante o login: $e');
  }
}

/// Cadastra um novo usuário no sistema
Future<Usuario> cadastrarUsuario(Usuario usuario) async {
  try {
    final response = await ApiService().post(
      '/usuarios/cadastrar',
      body: usuario.toJson(),
    );
    return Usuario.fromJson(response);
  } catch (e) {
    throw Exception('Erro durante o cadastro: $e');
  }
}

/// Obtém os dados do usuário do cache local
Future<Usuario?> _getUserFromCache(int userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('cached_user_$userId');
    final lastUpdate = prefs.getInt('last_user_cache_update_$userId') ?? 0;
    
    if (userJson != null) {
      // Verifica se os dados estão desatualizados (mais de 1 hora)
      final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
      if (cacheAge < 3600000) { // 1 hora em milissegundos
        return Usuario.fromJson(jsonDecode(userJson));
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Salva os dados do usuário no cache local
Future<void> _saveUserToCache(Usuario user) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_${user.id}', jsonEncode(user.toJson()));
    await prefs.setInt('last_user_cache_update_${user.id}', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('last_user_id', user.id);
  } catch (e) {
    log('Error saving user to cache: $e');
  }
}

/// Primeiro tenta buscar do cache local, se não encontrar ou estiver desatualizado, busca da API.
Future<Usuario> fetchFullUserProfile(int? userId, {bool forceRefresh = false}) async {
  // Se o userId for nulo, tenta obter do cache
  if (userId == null) {
    final currentUserId = await ApiService().getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('Nenhum usuário autenticado encontrado');
    }
    userId = currentUserId;
  }

  // Tenta buscar do cache primeiro, se não for forçado a atualizar
  if (!forceRefresh) {
    final cachedUser = await _getUserFromCache(userId);
    if (cachedUser != null) {
      return cachedUser;
    }
  }
  
  try {
    final response = await ApiService().get('/usuarios/$userId');
    final user = Usuario.fromJson(response);
    
    // Atualiza o cache
    await _saveUserToCache(user);
    
    return user;
  } catch (e) {
    throw Exception('Erro ao buscar Perfil do usuário: $e');
  }
}

/// Atualiza o Perfil do usuário no servidor e no cache local
Future<Usuario> updateUserProfile(Usuario usuario) async {
  try {
    final response = await ApiService().put(
      '/usuarios/${usuario.id}',
      body: usuario.toJson(),
    );
    
    final updatedUser = Usuario.fromJson(response);
    
    // Atualiza o cache local
    await _saveUserToCache(updatedUser);
    
    return updatedUser;
  } catch (e) {
    throw Exception('Erro ao atualizar perfil do usuário: $e');
  }
}

/// Faz o upload da foto de Perfil do usuário
Future<Usuario> uploadProfilePicture(int userId, String imagePath) async {
  try {
    final response = await ApiService().uploadFile(
      '/usuarios/$userId/foto',
      filePath: imagePath,
      fileField: 'foto',
    );
    
    final updatedUser = Usuario.fromJson(response);
    
    // Atualiza o cache local
    await _saveUserToCache(updatedUser);
    
    return updatedUser;
  } catch (e) {
    throw Exception('Erro ao enviar foto de Perfil: $e');
  }
}

/// Realiza o logout do usuário
Future<void> logout() async {
  try {
    // Limpa o token de autenticação
    await ApiService().removeToken();
    
    // Limpa o cache local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');
    await prefs.remove('current_user_id');
    
  } catch (e) {
    // Continua com o logout mesmo em caso de erro
  }
}

/// Verifica se existe um token de login armazenado localmente.
/// Retorna o ID do usuário se estiver logado, null caso contrário.
Future<int?> checkLoginStatus() async {
  try {
    final isLoggedIn = await ApiService().isLoggedIn();
    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('last_user_id');
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Busca apenas do cache local, sem fazer requisição ao backend.
/// Retorna `Usuario?` ou null se não houver cache válido.
Future<Usuario?> fetchUserProfileFromCacheOnly(int? userId) async {
  if (userId == null) {
    final currentUserId = await ApiService().getCurrentUserId();
    if (currentUserId == null) return null;
    userId = currentUserId;
  }

  try {
    final cachedUser = await _getUserFromCache(userId);
    return cachedUser;
  } catch (e) {
    return null;
  }
}
