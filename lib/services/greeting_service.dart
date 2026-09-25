import 'dart:math';

class GreetingService {
  static int getPeriod(int hour) {
    if (hour >= 5 && hour < 12) return 0; // Mañana
    if (hour >= 12 && hour < 19) return 1; // Tarde
    return 2; // Noche
  }

  static String getGreeting({
    required String userName,
    required String morningPool,
    required String afternoonPool,
    required String eveningPool,
    required String noTasksPool,
    required String busyDayPool,
    required String examPool,
    required String postExamPool,
    required String birthdayPool,
    int taskCount = 0,
    bool hasExamToday = false,
    bool hasFinishedExam = false,
    bool isBirthday = false,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final random = Random();

    String selectedPool;

    if (isBirthday) {
      selectedPool = birthdayPool;
    } else if (hasExamToday) {
      selectedPool = examPool;
    } else if (hasFinishedExam) {
      selectedPool = postExamPool;
    } else if (taskCount >= 5) {
      selectedPool = busyDayPool;
    } else if (taskCount == 0 && hour >= 5 && hour < 19 && random.nextDouble() < 0.3) {
      selectedPool = noTasksPool;
    } else {
      if (hour >= 5 && hour < 12) {
        selectedPool = morningPool;
      } else if (hour >= 12 && hour < 19) {
        selectedPool = afternoonPool;
      } else {
        selectedPool = eveningPool;
      }
    }

    final greetings = selectedPool.split('|');
    final greeting = greetings[random.nextInt(greetings.length)];
    
    // Extraer solo el primer nombre para un saludo más personal
    final firstName = userName.split(' ').first;
    return greeting.replaceAll('[name]', firstName);
  }
}
