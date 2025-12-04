import 'package:flutter/material.dart';
import 'package:mapafit/models/usuario_model.dart';

class UserProvider extends ChangeNotifier {
  UserType _userType = UserType.loggedOutUser;
  Usuario? _currentUser;

  UserType get userType => _userType;
  Usuario? get currentUser => _currentUser;

  void setUserType(UserType userType) {
    _userType = userType;
    if (userType == UserType.loggedOutUser) {
      _currentUser = null;
    }
    notifyListeners();
  }

  void updateCurrentUser(Usuario updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  void setCurrentUser(Usuario user) {
    _currentUser = user;
    _userType = UserType.loggedInUser;
    notifyListeners();
  }
}

enum UserType {
  loggedOutUser,
  loggedInUser,
}