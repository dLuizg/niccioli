import 'package:flutter/material.dart';
import 'package:niccioli/models/app_user_profile.dart';
import 'package:niccioli/screens/perfil/profile_detail_layout.dart';
import 'package:niccioli/services/auth_service.dart';
import 'package:niccioli/theme/app_colors.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _emptyValue = 'Preencha aqui';
  static const _driverInstitutions = [
    'UNIFAE',
    'UNIFEOB',
    'UNIFEOB Fazenda',
    'IF',
    'UNESP',
  ];

  late Future<AppUserProfile?> _profileFuture;
  AppUserProfile? _profile;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppUserProfile?> _loadProfile() async {
    final profile = await AuthService.instance.loadCurrentUserProfile();
    _profile = profile;
    return profile;
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? _emptyValue : trimmed;
  }

  String _displayList(List<String> values) {
    final cleaned = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return cleaned.isEmpty ? _emptyValue : cleaned.join(', ');
  }

  Future<void> _editTextField({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
    TextInputType? keyboardType,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _AccountEditDialog(
        title: title,
        initialValue: initialValue,
        emptyValue: _emptyValue,
        keyboardType: keyboardType,
      ),
    );

    if (!mounted || value == null) {
      return;
    }

    await _saveProfileChange(() => onSave(value));
  }

  Future<void> _manageInstitutions(AppUserProfile profile) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _InstitutionsDialog(
        options: _driverInstitutions,
        selectedValues: profile.servedInstitutions,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    await _saveProfileChange(
      () => AuthService.instance.updateCurrentUserProfile(
        servedInstitutions: selected,
      ),
    );
  }

  Future<void> _openStudentManager() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _DriverStudentsPage()));
    if (mounted) {
      await _reloadProfile();
    }
  }

  Future<void> _saveProfileChange(Future<void> Function() action) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await action();
      await _reloadProfile();
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveAlternatePoints(List<String> points) {
    return AuthService.instance.updateCurrentUserProfile(
      alternatePickupPoints: points,
    );
  }

  Future<void> _addAlternatePoint() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    await _editTextField(
      title: 'Ponto alternativo',
      initialValue: '',
      onSave: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          return Future.value();
        }
        return _saveAlternatePoints([
          ...profile.alternatePickupPoints,
          trimmed,
        ]);
      },
    );
  }

  Future<void> _editAlternatePoint(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.alternatePickupPoints.length) {
      return;
    }

    await _editTextField(
      title: 'Ponto alternativo',
      initialValue: profile.alternatePickupPoints[index],
      onSave: (value) {
        final updatedPoints = [...profile.alternatePickupPoints];
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          updatedPoints.removeAt(index);
        } else {
          updatedPoints[index] = trimmed;
        }
        return _saveAlternatePoints(updatedPoints);
      },
    );
  }

  Future<void> _deleteAlternatePoint(int index) async {
    final profile = _profile;
    if (profile == null || index >= profile.alternatePickupPoints.length) {
      return;
    }

    final updatedPoints = [...profile.alternatePickupPoints]..removeAt(index);
    await _saveProfileChange(() => _saveAlternatePoints(updatedPoints));
  }

  String _normalizeDeadline(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
    if (match == null) {
      throw const AuthFailure('Informe o horario no formato HH:mm.');
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw const AuthFailure('Informe um horario valido entre 00:00 e 23:59.');
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDetailScaffold(
      child: FutureBuilder<AppUserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 420,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return _AccountMessageState(
              message: error is AuthFailure
                  ? error.message
                  : 'Nao foi possivel carregar sua conta.',
              onRetry: _reloadProfile,
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return _AccountMessageState(
              message: 'Perfil nao encontrado. Entre em contato com o suporte.',
              onRetry: _reloadProfile,
            );
          }

          return _AccountContent(
            profile: profile,
            isSaving: _isSaving,
            errorMessage: _errorMessage,
            displayValue: _displayValue,
            displayList: _displayList,
            onEditName: () => _editTextField(
              title: 'Nome',
              initialValue: profile.name,
              onSave: (value) =>
                  AuthService.instance.updateCurrentUserProfile(name: value),
            ),
            onEditPhone: () => _editTextField(
              title: 'Telefone',
              initialValue: profile.phone ?? '',
              keyboardType: TextInputType.phone,
              onSave: (value) =>
                  AuthService.instance.updateCurrentUserProfile(phone: value),
            ),
            onEditAddress: () => _editTextField(
              title: 'Endereco',
              initialValue: profile.address ?? '',
              onSave: (value) =>
                  AuthService.instance.updateCurrentUserProfile(address: value),
            ),
            onEditDefaultPoint: () => _editTextField(
              title: 'Ponto padrao',
              initialValue: profile.defaultPickupPoint ?? '',
              onSave: (value) => AuthService.instance.updateCurrentUserProfile(
                defaultPickupPoint: value,
              ),
            ),
            onEditUniversity: () => _editTextField(
              title: 'Instituicao',
              initialValue: profile.university ?? '',
              onSave: (value) => AuthService.instance.updateCurrentUserProfile(
                university: value,
              ),
            ),
            onEditVehicle: () => _editTextField(
              title: 'Veiculo',
              initialValue: profile.vehicle ?? '',
              onSave: (value) =>
                  AuthService.instance.updateCurrentUserProfile(vehicle: value),
            ),
            onEditLicensePlate: () => _editTextField(
              title: 'Placa',
              initialValue: profile.licensePlate ?? '',
              onSave: (value) => AuthService.instance.updateCurrentUserProfile(
                licensePlate: value,
              ),
            ),
            onEditDefaultListDeadline: () => _editTextField(
              title: 'Horario limite padrao',
              initialValue: profile.defaultListDeadline ?? '',
              keyboardType: TextInputType.datetime,
              onSave: (value) {
                final normalized = _normalizeDeadline(value);
                return AuthService.instance.updateCurrentUserProfile(
                  defaultListDeadline: normalized,
                );
              },
            ),
            onManageInstitutions: () => _manageInstitutions(profile),
            onManageStudents: _openStudentManager,
            onAddAlternatePoint: _addAlternatePoint,
            onEditAlternatePoint: _editAlternatePoint,
            onDeleteAlternatePoint: _deleteAlternatePoint,
          );
        },
      ),
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.profile,
    required this.isSaving,
    required this.errorMessage,
    required this.displayValue,
    required this.displayList,
    required this.onEditName,
    required this.onEditPhone,
    required this.onEditAddress,
    required this.onEditDefaultPoint,
    required this.onEditUniversity,
    required this.onEditVehicle,
    required this.onEditLicensePlate,
    required this.onEditDefaultListDeadline,
    required this.onManageInstitutions,
    required this.onManageStudents,
    required this.onAddAlternatePoint,
    required this.onEditAlternatePoint,
    required this.onDeleteAlternatePoint,
  });

  final AppUserProfile profile;
  final bool isSaving;
  final String? errorMessage;
  final String Function(String? value) displayValue;
  final String Function(List<String> values) displayList;
  final VoidCallback onEditName;
  final VoidCallback onEditPhone;
  final VoidCallback onEditAddress;
  final VoidCallback onEditDefaultPoint;
  final VoidCallback onEditUniversity;
  final VoidCallback onEditVehicle;
  final VoidCallback onEditLicensePlate;
  final VoidCallback onEditDefaultListDeadline;
  final VoidCallback onManageInstitutions;
  final VoidCallback onManageStudents;
  final VoidCallback onAddAlternatePoint;
  final ValueChanged<int> onEditAlternatePoint;
  final ValueChanged<int> onDeleteAlternatePoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Configuracoes da Conta',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Center(child: _AccountAvatar()),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Foto do perfil indisponivel',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isSaving) ...[
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.orange,
            backgroundColor: AppColors.navBackground,
          ),
          const SizedBox(height: 12),
        ],
        if (errorMessage != null) ...[
          _AccountErrorMessage(message: errorMessage!),
          const SizedBox(height: 12),
        ],
        if (profile.role == AppUserRole.motorista)
          _DriverAccountFields(
            profile: profile,
            displayValue: displayValue,
            displayList: displayList,
            isSaving: isSaving,
            onEditName: onEditName,
            onEditPhone: onEditPhone,
            onEditVehicle: onEditVehicle,
            onEditLicensePlate: onEditLicensePlate,
            onEditDefaultListDeadline: onEditDefaultListDeadline,
            onManageInstitutions: onManageInstitutions,
            onManageStudents: onManageStudents,
          )
        else
          _StudentAccountFields(
            profile: profile,
            displayValue: displayValue,
            isSaving: isSaving,
            onEditName: onEditName,
            onEditPhone: onEditPhone,
            onEditAddress: onEditAddress,
            onEditDefaultPoint: onEditDefaultPoint,
            onEditUniversity: onEditUniversity,
            onAddAlternatePoint: onAddAlternatePoint,
            onEditAlternatePoint: onEditAlternatePoint,
            onDeleteAlternatePoint: onDeleteAlternatePoint,
          ),
      ],
    );
  }
}

class _StudentAccountFields extends StatelessWidget {
  const _StudentAccountFields({
    required this.profile,
    required this.displayValue,
    required this.isSaving,
    required this.onEditName,
    required this.onEditPhone,
    required this.onEditAddress,
    required this.onEditDefaultPoint,
    required this.onEditUniversity,
    required this.onAddAlternatePoint,
    required this.onEditAlternatePoint,
    required this.onDeleteAlternatePoint,
  });

  final AppUserProfile profile;
  final String Function(String? value) displayValue;
  final bool isSaving;
  final VoidCallback onEditName;
  final VoidCallback onEditPhone;
  final VoidCallback onEditAddress;
  final VoidCallback onEditDefaultPoint;
  final VoidCallback onEditUniversity;
  final VoidCallback onAddAlternatePoint;
  final ValueChanged<int> onEditAlternatePoint;
  final ValueChanged<int> onDeleteAlternatePoint;

  @override
  Widget build(BuildContext context) {
    final alternatePoints = profile.alternatePickupPoints;
    final universityIsLocked = profile.university?.trim().isNotEmpty == true;

    return Column(
      children: [
        _AccountInfoTile(
          icon: Icons.account_circle_outlined,
          label: 'Nome: ${displayValue(profile.name)}',
          onTap: isSaving ? null : onEditName,
        ),
        _AccountInfoTile(
          icon: Icons.mail_outline,
          label: 'E-mail: ${displayValue(profile.email)}',
          editable: false,
        ),
        _AccountInfoTile(
          icon: Icons.phone_outlined,
          label: 'Telefone: ${displayValue(profile.phone)}',
          onTap: isSaving ? null : onEditPhone,
        ),
        _AccountInfoTile(
          icon: Icons.map_outlined,
          label: 'Endereco: ${displayValue(profile.address)}',
          onTap: isSaving ? null : onEditAddress,
        ),
        _AccountInfoTile(
          icon: Icons.map_outlined,
          label: 'Ponto padrao: ${displayValue(profile.defaultPickupPoint)}',
          onTap: isSaving ? null : onEditDefaultPoint,
        ),
        _AccountInfoTile(
          icon: Icons.business_outlined,
          label: 'Instituicao: ${displayValue(profile.university)}',
          editable: !universityIsLocked,
          onTap: isSaving || universityIsLocked ? null : onEditUniversity,
        ),
        if (alternatePoints.isEmpty)
          _AccountInfoTile(
            icon: Icons.alt_route_outlined,
            label: 'Ponto alternativo: ${displayValue(null)}',
            onTap: isSaving ? null : onAddAlternatePoint,
          )
        else
          for (var index = 0; index < alternatePoints.length; index++)
            _AccountInfoTile(
              icon: Icons.alt_route_outlined,
              label:
                  'Ponto alternativo: ${displayValue(alternatePoints[index])}',
              onTap: isSaving ? null : () => onEditAlternatePoint(index),
              onDelete: isSaving ? null : () => onDeleteAlternatePoint(index),
            ),
        _AccountActionTile(
          label: 'Cadastrar novo ponto alternativo',
          onTap: isSaving ? null : onAddAlternatePoint,
        ),
      ],
    );
  }
}

class _DriverAccountFields extends StatelessWidget {
  const _DriverAccountFields({
    required this.profile,
    required this.displayValue,
    required this.displayList,
    required this.isSaving,
    required this.onEditName,
    required this.onEditPhone,
    required this.onEditVehicle,
    required this.onEditLicensePlate,
    required this.onEditDefaultListDeadline,
    required this.onManageInstitutions,
    required this.onManageStudents,
  });

  final AppUserProfile profile;
  final String Function(String? value) displayValue;
  final String Function(List<String> values) displayList;
  final bool isSaving;
  final VoidCallback onEditName;
  final VoidCallback onEditPhone;
  final VoidCallback onEditVehicle;
  final VoidCallback onEditLicensePlate;
  final VoidCallback onEditDefaultListDeadline;
  final VoidCallback onManageInstitutions;
  final VoidCallback onManageStudents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountInfoTile(
          icon: Icons.account_circle_outlined,
          label: 'Nome: ${displayValue(profile.name)}',
          onTap: isSaving ? null : onEditName,
        ),
        _AccountInfoTile(
          icon: Icons.mail_outline,
          label: 'E-mail: ${displayValue(profile.email)}',
          editable: false,
        ),
        _AccountInfoTile(
          icon: Icons.phone_outlined,
          label: 'Telefone: ${displayValue(profile.phone)}',
          onTap: isSaving ? null : onEditPhone,
        ),
        _AccountInfoTile(
          icon: Icons.navigation_outlined,
          label: 'Veiculo: ${displayValue(profile.vehicle)}',
          onTap: isSaving ? null : onEditVehicle,
        ),
        _AccountInfoTile(
          icon: Icons.tag,
          label: 'Placa: ${displayValue(profile.licensePlate)}',
          onTap: isSaving ? null : onEditLicensePlate,
        ),
        _AccountInfoTile(
          icon: Icons.schedule,
          label:
              'Horario limite padrao: ${displayValue(profile.defaultListDeadline)}',
          onTap: isSaving ? null : onEditDefaultListDeadline,
        ),
        _AccountInfoTile(
          icon: Icons.business_outlined,
          label:
              'Instituicoes atendidas: ${displayList(profile.servedInstitutions)}',
          onTap: isSaving ? null : onManageInstitutions,
        ),
        _AccountInfoTile(
          icon: Icons.account_circle_outlined,
          label: 'Gerenciar Alunos',
          onTap: isSaving ? null : onManageStudents,
        ),
      ],
    );
  }
}

class _AccountMessageState extends StatelessWidget {
  const _AccountMessageState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Tentar novamente',
                    style: TextStyle(color: AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _AccountEditDialog extends StatefulWidget {
  const _AccountEditDialog({
    required this.title,
    required this.initialValue,
    required this.emptyValue,
    this.keyboardType,
  });

  final String title;
  final String initialValue;
  final String emptyValue;
  final TextInputType? keyboardType;

  @override
  State<_AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navBackground,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: widget.emptyValue,
          hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.55)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.white.withValues(alpha: 0.35),
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.orange),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.white),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text(
            'Salvar',
            style: TextStyle(color: AppColors.orange),
          ),
        ),
      ],
    );
  }
}

class _InstitutionsDialog extends StatefulWidget {
  const _InstitutionsDialog({
    required this.options,
    required this.selectedValues,
  });

  final List<String> options;
  final List<String> selectedValues;

  @override
  State<_InstitutionsDialog> createState() => _InstitutionsDialogState();
}

class _InstitutionsDialogState extends State<_InstitutionsDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedValues};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navBackground,
      title: const Text(
        'Instituicoes atendidas',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in widget.options)
            CheckboxListTile(
              value: _selected.contains(option),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(option);
                  } else {
                    _selected.remove(option);
                  }
                });
              },
              activeColor: AppColors.orange,
              checkColor: AppColors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                option,
                style: const TextStyle(color: AppColors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.white),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            widget.options
                .where((option) => _selected.contains(option))
                .toList(),
          ),
          child: const Text(
            'Salvar',
            style: TextStyle(color: AppColors.orange),
          ),
        ),
      ],
    );
  }
}

class _DriverStudentsPage extends StatefulWidget {
  const _DriverStudentsPage();

  @override
  State<_DriverStudentsPage> createState() => _DriverStudentsPageState();
}

class _DriverStudentsPageState extends State<_DriverStudentsPage> {
  static const _emptyValue = 'Preencha aqui';

  final _cpfController = TextEditingController();
  late Future<List<AppUserProfile>> _studentsFuture;
  bool _isAdding = false;
  String? _removingStudentUid;
  String? _message;

  @override
  void initState() {
    super.initState();
    _studentsFuture = AuthService.instance.loadCurrentDriverStudents();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _reloadStudents() async {
    setState(() {
      _studentsFuture = AuthService.instance.loadCurrentDriverStudents();
    });
  }

  Future<void> _addStudent() async {
    if (_isAdding) {
      return;
    }

    setState(() {
      _isAdding = true;
      _message = null;
    });

    try {
      await AuthService.instance.addStudentToCurrentDriverByDocument(
        _cpfController.text,
      );
      _cpfController.clear();
      await _reloadStudents();
      if (mounted) {
        setState(() {
          _message = 'Aluno adicionado.';
        });
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _confirmRemoveStudent(AppUserProfile student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.navBackground,
        title: const Text(
          'Remover aluno',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Deseja remover ${_displayValue(student.name)} da sua lista?',
          style: const TextStyle(color: AppColors.white, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeStudent(student.uid);
    }
  }

  Future<void> _removeStudent(String studentUid) async {
    if (_removingStudentUid != null) {
      return;
    }

    setState(() {
      _removingStudentUid = studentUid;
      _message = null;
    });

    try {
      await AuthService.instance.removeStudentFromCurrentDriver(studentUid);
      await _reloadStudents();
      if (mounted) {
        setState(() {
          _message = 'Aluno removido.';
        });
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _removingStudentUid = null;
        });
      }
    }
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? _emptyValue : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDetailScaffold(
      headerLabel: 'GERENCIAR ALUNOS',
      contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Gerenciar Alunos',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 26),
          _CpfInputTile(
            controller: _cpfController,
            isAdding: _isAdding,
            onAdd: _addStudent,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _AccountErrorMessage(message: _message!),
          ],
          const SizedBox(height: 18),
          FutureBuilder<List<AppUserProfile>>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                return _AccountMessageState(
                  message: error is AuthFailure
                      ? error.message
                      : 'Nao foi possivel carregar os alunos.',
                  onRetry: _reloadStudents,
                );
              }

              final students = snapshot.data ?? const [];
              if (students.isEmpty) {
                return const _StudentsEmptyState();
              }

              return Column(
                children: [
                  for (final student in students)
                    _StudentListTile(
                      name: _displayValue(student.name),
                      institution: _displayValue(student.university),
                      isRemoving: _removingStudentUid == student.uid,
                      onDelete: () => _confirmRemoveStudent(student),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CpfInputTile extends StatelessWidget {
  const _CpfInputTile({
    required this.controller,
    required this.isAdding,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isAdding,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'CPF do aluno',
                hintStyle: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: isAdding ? null : onAdd,
            icon: Icon(
              isAdding ? Icons.hourglass_empty : Icons.add,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsEmptyState extends StatelessWidget {
  const _StudentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Nenhum aluno adicionado.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.white.withValues(alpha: 0.72),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  const _StudentListTile({
    required this.name,
    required this.institution,
    required this.isRemoving,
    required this.onDelete,
  });

  final String name;
  final String institution;
  final bool isRemoving;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ProfileDarkTile(
      leading: const Icon(
        Icons.account_circle_outlined,
        color: AppColors.white,
        size: 16,
      ),
      height: 44,
      trailing: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: isRemoving ? null : onDelete,
        icon: Icon(
          isRemoving ? Icons.hourglass_empty : Icons.delete_outline,
          color: AppColors.white,
          size: 18,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            institution,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.68),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
      child: const CircleAvatar(backgroundColor: Color(0xFFD6D6D6)),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.onDelete,
    this.editable = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (editable)
          const Icon(Icons.edit_square, color: AppColors.white, size: 15),
        if (onDelete != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.white,
              size: 17,
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: editable ? onTap : null,
      child: ProfileDarkTile(
        leading: Icon(icon, color: AppColors.white, size: 16),
        trailing: trailing.children.isEmpty ? null : trailing,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ProfileDarkTile(
        leading: const Icon(Icons.add, color: AppColors.white, size: 18),
        height: 34,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AccountErrorMessage extends StatelessWidget {
  const _AccountErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFFFC3B8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
