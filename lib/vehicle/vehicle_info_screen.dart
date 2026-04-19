import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import 'vehicle_model.dart';
import 'vehicle_service.dart';
import 'vehicle_constants.dart';
import '../notifications/notification_service.dart';

/// Écran de saisie/modification des informations du véhicule
class VehicleInfoScreen extends StatefulWidget {
  final Vehicle? existingVehicle;

  const VehicleInfoScreen({
    super.key,
    this.existingVehicle,
  });

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();

  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  String? _selectedBrand;
  FuelType _selectedFuelType = FuelType.essence;
  bool _isLoading = false;

  bool get _isEditMode => widget.existingVehicle != null;

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
  }

  void _prefillIfEditing() {
    final v = widget.existingVehicle;
    if (v == null) return;

    _selectedBrand = v.brand;
    _modelController.text = v.model;
    _yearController.text = v.year.toString();
    _mileageController.text = v.currentMileage.toString();
    _selectedFuelType = v.fuelType;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBrand == null) {
      _showSnackBar('Veuillez sélectionner une marque', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final vehicle = Vehicle(
      brand: _selectedBrand!,
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text),
      fuelType: _selectedFuelType,
      currentMileage: int.parse(_mileageController.text),
      createdAt: widget.existingVehicle?.createdAt ?? now,
      updatedAt: now,
    );

    final errorMessage = await _vehicleService.saveVehicle(vehicle);
    // Programmer le rappel de mise à jour du kilométrage
    await NotificationService().scheduleMileageReminder();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      _showSnackBar(errorMessage, isError: true);
    } else {
      _showSnackBar(
        _isEditMode
            ? 'Véhicule mis à jour !'
            : 'Véhicule enregistré avec succès !',
        isError: false,
      );

      if (_isEditMode && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppTheme.severityRed : AppTheme.severityGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier mon véhicule' : 'Mon véhicule'),
        automaticallyImplyLeading: _isEditMode,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isEditMode) _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildBrandDropdown(),
                const SizedBox(height: 16),
                _buildModelField(),
                const SizedBox(height: 16),
                _buildYearField(),
                const SizedBox(height: 16),
                _buildMileageField(),
                const SizedBox(height: 24),
                _buildFuelTypeSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SOUS-WIDGETS
  // ==========================================================================

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlueLight,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            size: 50,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Parlez-nous de votre voiture',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ces informations nous aideront à vous fournir des conseils personnalisés.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBrand,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Marque',
        hintText: 'Sélectionnez une marque',
        prefixIcon: Icon(Icons.factory_outlined, color: AppTheme.primaryBlue),
      ),
      items: VehicleConstants.carBrands.map((brand) {
        return DropdownMenuItem<String>(
          value: brand,
          child: Text(brand),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedBrand = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner une marque';
        }
        return null;
      },
    );
  }

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Modèle',
        hintText: 'ex: Clio, 208, Sandero',
        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryBlue),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer le modèle';
        }
        if (value.trim().length < 2) {
          return 'Modèle trop court';
        }
        return null;
      },
    );
  }

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: const InputDecoration(
        labelText: 'Année',
        hintText: 'ex: 2020',
        prefixIcon:
            Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBlue),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer l\'année';
        }
        final year = int.tryParse(value);
        if (year == null) return 'Année invalide';

        final currentYear = DateTime.now().year;
        if (year < VehicleConstants.minYear) {
          return 'Année trop ancienne (min ${VehicleConstants.minYear})';
        }
        if (year > currentYear + 1) {
          return 'Année dans le futur';
        }
        return null;
      },
    );
  }

  Widget _buildMileageField() {
    return TextFormField(
      controller: _mileageController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(7),
      ],
      decoration: const InputDecoration(
        labelText: 'Kilométrage actuel',
        hintText: 'ex: 85000',
        prefixIcon: Icon(Icons.speed_outlined, color: AppTheme.primaryBlue),
        suffixText: 'km',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer le kilométrage';
        }
        final mileage = int.tryParse(value);
        if (mileage == null) return 'Kilométrage invalide';
        if (mileage < 0) return 'Valeur négative impossible';
        if (mileage > VehicleConstants.maxMileage) {
          return 'Valeur trop élevée';
        }
        return null;
      },
    );
  }

  Widget _buildFuelTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de carburant',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildFuelCard(FuelType.essence)),
            const SizedBox(width: 12),
            Expanded(child: _buildFuelCard(FuelType.diesel)),
          ],
        ),
      ],
    );
  }

  Widget _buildFuelCard(FuelType fuelType) {
    final isSelected = _selectedFuelType == fuelType;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFuelType = fuelType);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlueLight : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              fuelType.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              fuelType.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSave,
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(_isEditMode ? 'Enregistrer' : 'Continuer'),
    );
  }
}