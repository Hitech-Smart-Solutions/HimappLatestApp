class PagePermission {
  final int programId;
  final int companyId;
  final int moduleId;
  final String programName;
  final bool isModuleAdmin;
  final bool canAdd;
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool canExport;
  final String pageName;
  final String moduleName;
  final String iconName;
  final String moduleIconName;
  final int projectId;

  PagePermission({
    required this.programId,
    required this.companyId,
    required this.moduleId,
    required this.programName,
    required this.isModuleAdmin,
    required this.canAdd,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.canExport,
    required this.pageName,
    required this.moduleName,
    required this.iconName,
    required this.moduleIconName,
    required this.projectId,
  });

  factory PagePermission.fromJson(Map<String, dynamic> json) {
    return PagePermission(
      programId: json['ProgramID'] ?? 0,
      companyId: json['CompanyID'] ?? 0,
      moduleId: json['ModuleID'] ?? 0,
      programName: json['programname'] ?? '',
      isModuleAdmin: json['ismoduleadmin'] ?? false,
      canAdd: json['canadd'] ?? false,
      canView: json['canview'] ?? false,
      canEdit: json['canedit'] ?? false,
      canDelete: json['candelete'] ?? false,
      canExport: json['canexport'] ?? false,
      pageName: json['pagename'] ?? '',
      moduleName: json['modulename'] ?? '',
      iconName: json['iconname'] ?? '',
      moduleIconName: json['moduleiconname'] ?? '',
      projectId: json['projectid'] ?? 0,
    );
  }
}
