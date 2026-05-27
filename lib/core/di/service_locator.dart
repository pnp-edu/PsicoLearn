import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:psicolearn/core/services/storage_service.dart';
import 'package:psicolearn/core/services/notification_service.dart';
import 'package:psicolearn/features/personality_test/domain/services/personality_test_service.dart';
import 'package:psicolearn/features/spatial_test/domain/services/spatial_test_service.dart';
import 'package:psicolearn/features/interview/domain/services/interview_service.dart';
import 'package:psicolearn/features/personality_test/data/repositories/question_repository.dart';
import 'package:psicolearn/core/services/security_service.dart';


final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  StorageService storageService;
  
  try {
    debugPrint('💾 sl: Inicializando Hive...');
    final hiveService = HiveStorageService();
    await hiveService.init();
    storageService = hiveService;
    debugPrint('✅ sl: Hive listo.');
  } catch (e) {
    debugPrint('⚠️ sl: Fallo en Hive ($e). Activando SharedPreferences...');
    final spService = SharedPreferencesService();
    await spService.init();
    storageService = spService;
  }

  sl.registerSingleton<StorageService>(storageService);

  debugPrint('⚙️ sl: Registrando servicios de dominio...');
  sl.registerLazySingleton<PersonalityTestService>(
    () => PersonalityTestService(sl<StorageService>()),
  );

  sl.registerLazySingleton<SpatialTestService>(
    () => SpatialTestService(sl<StorageService>()),
  );

  sl.registerLazySingleton<InterviewService>(
    () => InterviewService(),
  );

  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  
  sl.registerLazySingleton<SecurityService>(() => SecurityService());
  


  debugPrint('📚 sl: Pre-calentando banco de preguntas...');
  await QuestionRepository.loadQuestionsFromAssets();
  debugPrint('✅ sl: Banco de preguntas en caché.');
}
