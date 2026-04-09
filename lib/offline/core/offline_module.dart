enum OfflineModule {
  lead,
  deal,
  task,
  myTask,
  chatList,
  chatMessages,
  userProfile,
  settings,
  fieldConfig,
  referenceData,
}

extension OfflineModuleX on OfflineModule {
  String get value => name;
}
