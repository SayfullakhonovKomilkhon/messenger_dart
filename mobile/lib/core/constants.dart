

class AppConstants {
  // IP адрес компьютера с бекендом в локальной сети
  // Для эмулятора Android используйте 10.0.2.2
  // Для физических устройств используйте реальный IP компьютера
  static const String _host = '192.168.1.114';
  static const int _port = 3000;

  static String get apiBaseUrl => 'http://$_host:$_port/api/v1';

  static String get wsUrl => 'ws://$_host:$_port/ws';

  static const int messagePageSize = 30;
}
