import 'dart:async';

import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(const ProdMonApp());
}

// ============================================================
// APPLICATION
// ============================================================

class ProdMonApp extends StatelessWidget {
  const ProdMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProdMon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        "Veuillez saisir votre adresse e-mail et votre mot de passe.",
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result = await ApiService.login(email, password);

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (result['success'] == true) {
      final dynamic rawUserId = result['userId'];

      final int? userId = rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId.toString());

      if (userId == null) {
        showMessage(
          "Le serveur n'a pas retourné un identifiant utilisateur valide.",
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            userId: userId,
            email: result['email']?.toString() ?? email,
          ),
        ),
      );
    } else {
      showMessage(
        result['message']?.toString() ?? "Impossible de se connecter.",
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing,
                          size: 45,
                          color: Color(0xFFE53935),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "PRODMON",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Production Monitoring",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Connexion sécurisée",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Adresse e-mail",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        onSubmitted: (_) {
                          if (!loading) {
                            login();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: loading ? null : login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            loading ? "Connexion..." : "Se connecter",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 17,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Authentification avec vérification OTP",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OTP
// ============================================================

class OtpPage extends StatefulWidget {
  final int userId;
  final String email;

  const OtpPage({super.key, required this.userId, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();

  bool loading = false;

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      showMessage("Veuillez saisir le code OTP à 6 chiffres.");
      return;
    }

    setState(() {
      loading = true;
    });

    final result = await ApiService.verifyOtp(widget.userId, code);

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (result['success'] != true) {
      showMessage(result['message']?.toString() ?? "Code OTP incorrect.");
      return;
    }

    final dynamic rawUser = result['user'];

    if (rawUser is! Map) {
      showMessage("Réponse utilisateur invalide reçue du serveur.");
      return;
    }

    final user = Map<String, dynamic>.from(rawUser);

    final username = user['username']?.toString() ?? "Utilisateur";
    final email = user['email']?.toString() ?? widget.email;
    final role = user['role']?.toString().trim() ?? "User";

    final dynamic rawVerifiedUserId = user['id'];
    final int verifiedUserId = rawVerifiedUserId is int
        ? rawVerifiedUserId
        : int.tryParse(rawVerifiedUserId?.toString() ?? '') ?? widget.userId;

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PinAccessPage(
          userId: verifiedUserId,
          username: username,
          email: email,
          role: role,
        ),
      ),
      (route) => false,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification OTP")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFFE53935),
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Vérification de sécurité",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Un code OTP a été envoyé à",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Le code est valable pendant 5 minutes.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                        ),
                        onSubmitted: (_) {
                          if (!loading) {
                            verifyOtp();
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: "Code OTP",
                          hintText: "000000",
                          counterText: "",
                          prefixIcon: Icon(Icons.password_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: loading ? null : verifyOtp,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified),
                          label: Text(
                            loading ? "Vérification..." : "Vérifier le code",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACCÈS PERSONNEL PAR PIN APRÈS OTP
// ============================================================

class PinAccessPage extends StatefulWidget {
  final int userId;
  final String username;
  final String email;
  final String role;

  const PinAccessPage({
    super.key,
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  State<PinAccessPage> createState() => _PinAccessPageState();
}

class _PinAccessPageState extends State<PinAccessPage> {
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();

  bool loading = false;
  bool setupMode = false;
  bool hidePin = true;

  String get roleLabel {
    switch (widget.role.trim().toLowerCase()) {
      case "directeur":
        return "Directeur";
      case "chefproduction":
      case "chef_production":
      case "chef production":
        return "Chef de production";
      case "maintenance":
      case "technicien":
        return "Maintenance";
      case "user":
      case "operator":
      case "operateur":
      case "opérateur":
        return "Opérateur";
      default:
        return widget.role;
    }
  }

  Future<void> submitPin() async {
    final pin = pinController.text.trim();

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      showMessage("Le PIN doit contenir entre 4 et 6 chiffres.");
      return;
    }

    if (setupMode) {
      final confirmation = confirmPinController.text.trim();

      if (pin != confirmation) {
        showMessage("Les deux PIN ne correspondent pas.");
        return;
      }

      setState(() => loading = true);

      final result = await ApiService.setPin(widget.userId, pin);

      if (!mounted) return;
      setState(() => loading = false);

      if (result['success'] == true) {
        showMessage(
          result['message']?.toString() ?? "PIN personnel enregistré.",
        );
        openRoleSpace();
      } else {
        showMessage(
          result['message']?.toString() ?? "Impossible d'enregistrer le PIN.",
        );
      }

      return;
    }

    setState(() => loading = true);

    final result = await ApiService.verifyPin(widget.userId, pin);

    if (!mounted) return;
    setState(() => loading = false);

    if (result['success'] == true) {
      openRoleSpace();
      return;
    }

    if (result['requiresPinSetup'] == true) {
      setState(() {
        setupMode = true;
        pinController.clear();
        confirmPinController.clear();
      });

      showMessage("Créez maintenant votre PIN personnel.");
      return;
    }

    showMessage(result['message']?.toString() ?? "PIN incorrect.");
  }

  void openRoleSpace() {
    final roleLower = widget.role.toLowerCase().trim();
    late Widget destinationPage;

    switch (roleLower) {
      case "admin":
        showMessage(
          "L'espace Administrateur est disponible sur le Dashboard Web.",
        );
        return;

      case "directeur":
      case "chefproduction":
      case "chef_production":
      case "chef production":
        destinationPage = AdminPage(
          userId: widget.userId,
          username: widget.username,
          email: widget.email,
          role: widget.role,
        );
        break;

      case "maintenance":
      case "technicien":
        destinationPage = MaintenancePage(
          username: widget.username,
          email: widget.email,
        );
        break;

      case "user":
      case "operator":
      case "operateur":
      case "opérateur":
        destinationPage = UserPage(
          username: widget.username,
          email: widget.email,
          role: widget.role,
        );
        break;

      default:
        showMessage("Rôle utilisateur non reconnu : ${widget.role}");
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destinationPage),
      (route) => false,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(setupMode ? "Créer mon PIN" : "Accès à mon espace"),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_outlined,
                          color: Color(0xFFE53935),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Bonjour ${widget.username}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 14),
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 18),
                        label: Text(roleLabel),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        setupMode
                            ? "Première connexion : créez votre PIN personnel."
                            : "Saisissez votre PIN personnel pour accéder à votre espace.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: hidePin,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          labelText: setupMode
                              ? "Nouveau PIN"
                              : "PIN personnel",
                          counterText: "",
                          prefixIcon: const Icon(Icons.pin_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => hidePin = !hidePin);
                            },
                            icon: Icon(
                              hidePin
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (setupMode) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: confirmPinController,
                          keyboardType: TextInputType.number,
                          obscureText: hidePin,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          onSubmitted: (_) {
                            if (!loading) submitPin();
                          },
                          decoration: const InputDecoration(
                            labelText: "Confirmer le PIN",
                            counterText: "",
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: loading ? null : submitPin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  setupMode
                                      ? Icons.save_outlined
                                      : Icons.lock_open_outlined,
                                ),
                          label: Text(
                            loading
                                ? "Vérification..."
                                : setupMode
                                ? "Enregistrer mon PIN"
                                : "Accéder à mon espace",
                          ),
                        ),
                      ),
                      if (!setupMode) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    setupMode = true;
                                    pinController.clear();
                                    confirmPinController.clear();
                                  });
                                },
                          child: const Text(
                            "Première connexion ? Créer mon PIN",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN
// ============================================================

class AdminPage extends StatefulWidget {
  final int userId;
  final String username;
  final String email;
  final String role;

  const AdminPage({
    super.key,
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool get isAdmin => widget.role.trim().toLowerCase() == "admin";

  bool get isDirecteur => widget.role.trim().toLowerCase() == "directeur";

  bool get isChefProduction {
    final role = widget.role.trim().toLowerCase();
    return role == "chefproduction" ||
        role == "chef_production" ||
        role == "chef production";
  }

  // Le directeur consulte les informations mais ne pilote pas les machines.
  bool get canAccessCommands => !isDirecteur;

  IconData get roleIcon {
    if (isAdmin) return Icons.admin_panel_settings;
    if (isDirecteur) return Icons.business_center_outlined;
    if (isChefProduction) return Icons.supervisor_account_outlined;
    return Icons.badge_outlined;
  }

  String get roleDescription {
    if (isAdmin) {
      return "Administration complète et supervision";
    }
    if (isDirecteur) {
      return "Consultation globale et suivi de la production";
    }
    if (isChefProduction) {
      return "Pilotage de la production et des commandes";
    }
    return "Accès ProdMon selon votre rôle";
  }

  String get roleLabel {
    final role = widget.role.trim().toLowerCase();

    switch (role) {
      case "admin":
        return "Administrateur";
      case "directeur":
        return "Directeur";
      case "chefproduction":
      case "chef_production":
      case "chef production":
        return "Chef de production";
      default:
        return widget.role;
    }
  }

  final MQTTService mqttService = MQTTService();

  StreamSubscription<void>? mqttSubscription;
  StreamSubscription<Map<String, dynamic>>? ackSubscription;

  bool mqttConnected = false;
  bool connectingMqtt = true;

  // ================= COMMANDES =================

  bool commandSending = false;

  bool commandsLoading = false;
  bool commandsLoaded = false;

  List<dynamic> commands = [];

  String? commandsError;
  int? selectedCommandMachineId;

  // ================= MACHINES API =================

  bool machinesLoading = false;
  bool machinesLoaded = false;

  List<dynamic> machines = [];

  String? machinesError;

  // ================= PRODUCTION API =================

  bool productionLoading = false;
  bool productionLoaded = false;

  List<dynamic> productionData = [];

  String? productionError;
  int? selectedProductionMachineId;

  // ================= ALERTES API =================

  bool alertsLoading = false;
  bool alertsLoaded = false;

  List<dynamic> alerts = [];

  String? alertsError;
  int? selectedAlertMachineId;

  // ================= NOTIFICATIONS API =================

  bool notificationsLoading = false;
  bool notificationsLoaded = false;
  List<dynamic> notifications = [];
  String? notificationsError;
  int? selectedNotificationAlertId;

  // ================= UTILISATEURS API =================

  bool usersLoading = false;
  bool usersLoaded = false;

  List<dynamic> users = [];

  String? usersError;

  // ================= NAVIGATION =================

  int selectedPage = 0;

  final List<String> pageTitles = const [
    "Tableau de bord",
    "Machines",
    "Production",
    "Alertes",
    "Notifications",
    "Utilisateurs",
    "Commandes",
    "Profil",
  ];

  @override
  void initState() {
    super.initState();

    mqttSubscription = mqttService.updates.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    ackSubscription = mqttService.ackUpdates.listen((ack) {
      handleCommandAck(ack);
    });

    connectMQTT();
  }

  // ============================================================
  // MQTT
  // ============================================================

  Future<void> connectMQTT() async {
    final result = await mqttService.connect();

    if (!mounted) return;

    setState(() {
      mqttConnected = result;
      connectingMqtt = false;
    });
  }

  // ============================================================
  // CHARGER LES MACHINES DEPUIS L'API
  // ============================================================

  Future<void> loadMachines() async {
    if (machinesLoading) {
      return;
    }

    setState(() {
      machinesLoading = true;
      machinesError = null;
    });

    final result = await ApiService.getMachines();

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedMachines = result['machines'];

      setState(() {
        machines = receivedMachines is List ? receivedMachines : [];

        machinesLoading = false;
        machinesLoaded = true;
      });
    } else {
      setState(() {
        machinesLoading = false;
        machinesError =
            result['message']?.toString() ??
            "Impossible de charger les machines.";
      });
    }
  }

  // ============================================================
  // CHARGER LES DONNÉES DE PRODUCTION DEPUIS L'API
  // ============================================================

  Future<void> loadProduction({int? machineId}) async {
    if (productionLoading) {
      return;
    }

    setState(() {
      productionLoading = true;
      productionError = null;
      selectedProductionMachineId = machineId;
    });

    final result = machineId == null
        ? await ApiService.getMachineData()
        : await ApiService.getMachineDataByMachine(machineId);

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedData = result['data'];

      setState(() {
        productionData = receivedData is List ? receivedData : [];
        productionLoading = false;
        productionLoaded = true;
      });
    } else {
      setState(() {
        productionLoading = false;
        productionError =
            result['message']?.toString() ??
            "Impossible de charger les données de production.";
      });
    }
  }

  // ============================================================
  // CHARGER LES ALERTES DEPUIS L'API
  // ============================================================

  Future<void> loadAlerts({int? machineId}) async {
    if (alertsLoading) {
      return;
    }

    setState(() {
      alertsLoading = true;
      alertsError = null;
      selectedAlertMachineId = machineId;
    });

    final result = machineId == null
        ? await ApiService.getAlerts()
        : await ApiService.getAlertsByMachine(machineId);

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedAlerts = result['alerts'];

      setState(() {
        alerts = receivedAlerts is List ? receivedAlerts : [];
        alertsLoading = false;
        alertsLoaded = true;
      });
    } else {
      setState(() {
        alertsLoading = false;
        alertsError =
            result['message']?.toString() ??
            "Impossible de charger les alertes.";
      });
    }
  }

  // ============================================================
  // CHARGER LES NOTIFICATIONS DEPUIS L'API
  // ============================================================

  Future<void> loadNotifications({int? alertId}) async {
    if (notificationsLoading) return;

    setState(() {
      notificationsLoading = true;
      notificationsError = null;
      selectedNotificationAlertId = alertId;
    });

    final result = alertId == null
        ? await ApiService.getNotifications()
        : await ApiService.getNotificationsByAlert(alertId);

    if (!mounted) return;

    if (result['success'] == true) {
      final received = result['notifications'];
      setState(() {
        notifications = received is List ? received : [];
        notificationsLoading = false;
        notificationsLoaded = true;
      });
    } else {
      setState(() {
        notificationsLoading = false;
        notificationsError =
            result['message']?.toString() ??
            "Impossible de charger les notifications.";
      });
    }
  }

  // ============================================================
  // CHARGER LES UTILISATEURS DEPUIS L'API
  // ============================================================

  Future<void> loadUsers() async {
    if (usersLoading) {
      return;
    }

    setState(() {
      usersLoading = true;
      usersError = null;
    });

    final result = await ApiService.getUsers();

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedUsers = result['users'];

      setState(() {
        users = receivedUsers is List ? receivedUsers : [];
        usersLoading = false;
        usersLoaded = true;
      });
    } else {
      setState(() {
        usersLoading = false;
        usersError =
            result['message']?.toString() ??
            "Impossible de charger les utilisateurs.";
      });
    }
  }

  // ============================================================
  // CHARGER LES COMMANDES DEPUIS L'API
  // ============================================================

  Future<void> loadCommands({int? machineId}) async {
    if (commandsLoading) {
      return;
    }

    setState(() {
      commandsLoading = true;
      commandsError = null;
      selectedCommandMachineId = machineId;
    });

    final result = machineId == null
        ? await ApiService.getCommands()
        : await ApiService.getCommandsByMachine(machineId);

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedCommands = result['commands'];

      setState(() {
        commands = receivedCommands is List ? receivedCommands : [];
        commandsLoading = false;
        commandsLoaded = true;
      });
    } else {
      setState(() {
        commandsLoading = false;
        commandsError =
            result['message']?.toString() ??
            "Impossible de charger l'historique des commandes.";
      });
    }
  }

  // ============================================================
  // TRAITER L'ACK REÇU DE L'ESP32
  // ============================================================

  Future<void> handleCommandAck(Map<String, dynamic> ack) async {
    final int? commandId = int.tryParse(ack['commandId']?.toString() ?? '');

    final String statut = ack['status']?.toString().trim().toUpperCase() ?? '';

    final String commande = ack['command']?.toString().trim() ?? '';

    if (commandId == null || commandId <= 0 || statut.isEmpty) {
      return;
    }

    final result = await ApiService.updateCommandStatus(
      commandId: commandId,
      statut: statut,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await loadCommands(machineId: selectedCommandMachineId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "ACK ESP32 reçu : $commande → $statut (commande #$commandId).",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: statut == "EXECUTEE" ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                "ACK reçu, mais le statut n'a pas pu être mis à jour.",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ============================================================
  // NAVIGATION MENU
  // ============================================================

  void selectPage(int index) {
    if (index == 5 && !isAdmin) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "La gestion des utilisateurs est réservée à l'administrateur.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (index == 6 && !canAccessCommands) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Le profil Directeur est en consultation : les commandes machine sont désactivées.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      selectedPage = index;
    });

    Navigator.pop(context);

    if (index == 1 && !machinesLoaded) {
      loadMachines();
    }

    if (index == 2 && !productionLoaded) {
      loadProduction();
    }

    if (index == 2 && !machinesLoaded) {
      loadMachines();
    }

    if (index == 3 && !alertsLoaded) {
      loadAlerts();
    }

    if (index == 3 && !machinesLoaded) {
      loadMachines();
    }

    if (index == 4 && !notificationsLoaded) {
      loadNotifications();
    }

    if (index == 5 && isAdmin && !usersLoaded) {
      loadUsers();
    }

    if (index == 6 && canAccessCommands && !commandsLoaded) {
      loadCommands();
    }

    if (index == 6 && canAccessCommands && !machinesLoaded) {
      loadMachines();
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    mqttSubscription?.cancel();
    ackSubscription?.cancel();
    mqttService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildAdminDrawer(),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        title: Text(
          "ProdMon • ${pageTitles[selectedPage]}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: buildCurrentPage(),
    );
  }

  // ============================================================
  // MENU ADMIN
  // ============================================================

  Widget buildAdminDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              color: const Color(0xFFE53935),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      roleIcon,
                      color: const Color(0xFFE53935),
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.email,
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    roleDescription,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  drawerItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    title: "Tableau de bord",
                  ),

                  drawerItem(
                    index: 1,
                    icon: Icons.precision_manufacturing,
                    title: "Machines",
                  ),

                  drawerItem(
                    index: 2,
                    icon: Icons.bar_chart,
                    title: "Production",
                  ),

                  drawerItem(
                    index: 3,
                    icon: Icons.warning_amber_outlined,
                    title: "Alertes",
                  ),

                  drawerItem(
                    index: 4,
                    icon: Icons.notifications_none,
                    title: "Notifications",
                  ),

                  if (isAdmin)
                    drawerItem(
                      index: 5,
                      icon: Icons.people_outline,
                      title: "Utilisateurs",
                    ),

                  if (canAccessCommands)
                    drawerItem(
                      index: 6,
                      icon: Icons.settings_remote,
                      title: "Commandes",
                    ),

                  const Divider(),

                  drawerItem(
                    index: 7,
                    icon: Icons.person_outline,
                    title: "Profil",
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Déconnexion",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: logout,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget drawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final selected = selectedPage == index;

    return ListTile(
      selected: selected,
      selectedTileColor: Colors.red.shade50,
      leading: Icon(
        icon,
        color: selected ? const Color(0xFFE53935) : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? const Color(0xFFE53935) : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => selectPage(index),
    );
  }

  // ============================================================
  // NAVIGATION ADMIN
  // ============================================================

  Widget buildCurrentPage() {
    switch (selectedPage) {
      case 0:
        return dashboardPage();

      case 1:
        return machinesPage();

      case 2:
        return productionPage();

      case 3:
        return alertsPage();

      case 4:
        return notificationsPage();

      case 5:
        return isAdmin ? usersPage() : dashboardPage();

      case 6:
        return canAccessCommands ? commandsPage() : dashboardPage();

      case 7:
        return profilePage();

      default:
        return dashboardPage();
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget dashboardPage() {
    final running = mqttService.machineState.toUpperCase() == "RUNNING";

    return RefreshIndicator(
      onRefresh: connectMQTT,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          welcomeCard(),

          const SizedBox(height: 18),

          const Text(
            "Vue générale",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: statCard(
                  title: "Machine 1",
                  value: mqttService.machineState,
                  icon: Icons.precision_manufacturing,
                  color: running ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: statCard(
                  title: "Production",
                  value: "${mqttService.production}",
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: statCard(
                  title: "Température",
                  value: "${mqttService.temperature.toStringAsFixed(1)} °C",
                  icon: Icons.thermostat,
                  color: mqttService.temperature >= 70
                      ? Colors.red
                      : Colors.orange,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: statCard(
                  title: "MQTT",
                  value: connectingMqtt
                      ? "Connexion..."
                      : mqttConnected
                      ? "Connecté"
                      : "Déconnecté",
                  icon: Icons.cloud_outlined,
                  color: mqttConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (mqttService.help)
            Card(
              color: Colors.red.shade50,
              child: const ListTile(
                leading: Icon(
                  Icons.notification_important,
                  color: Colors.red,
                  size: 36,
                ),
                title: Text(
                  "Demande d'aide",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text("La Machine 1 demande une assistance."),
              ),
            )
          else
            Card(
              color: Colors.green.shade50,
              child: const ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 34,
                ),
                title: Text(
                  "Aucune demande d'aide",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("La ligne ne signale aucune demande."),
              ),
            ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.precision_manufacturing,
                color: Colors.green,
              ),
              title: const Text(
                "Machines",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Consulter les équipements"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  selectedPage = 1;
                });

                if (!machinesLoaded) {
                  loadMachines();
                }
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: const Text(
                "Alertes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Consulter les alertes enregistrées"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  selectedPage = 3;
                });

                if (!alertsLoaded) {
                  loadAlerts();
                }

                if (!machinesLoaded) {
                  loadMachines();
                }
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.purple),
              title: const Text(
                "Notifications",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Historique des notifications"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  selectedPage = 4;
                });

                if (!notificationsLoaded) {
                  loadNotifications();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MACHINES - API RÉELLE
  // ============================================================

  Widget machinesPage() {
    if (!machinesLoaded && !machinesLoading && machinesError == null) {
      Future.microtask(loadMachines);
    }

    if (machinesLoading && machines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (machinesError != null && machines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 60),

              const SizedBox(height: 16),

              const Text(
                "Impossible de charger les machines",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                machinesError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: loadMachines,
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    if (machinesLoaded && machines.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadMachines,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),

            Icon(
              Icons.precision_manufacturing_outlined,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 15),

            Center(
              child: Text(
                "Aucune machine enregistrée",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadMachines,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Machines",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text("État des équipements de production"),
                  ],
                ),
              ),

              IconButton(
                tooltip: "Actualiser",
                onPressed: machinesLoading ? null : loadMachines,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: Icon(Icons.precision_manufacturing),
              ),
              title: Text(
                "${machines.length} machine${machines.length > 1 ? 's' : ''}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Enregistrée(s) dans ProdMon"),
            ),
          ),

          const SizedBox(height: 10),

          ...machines.map((machine) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              machine as Map,
            );

            final int id = int.tryParse(data['id']?.toString() ?? '') ?? 0;

            final String nom = data['nom']?.toString() ?? "Machine $id";

            final String localisation =
                data['localisation']?.toString() ?? "Localisation non définie";

            final String statut =
                data['statut']?.toString().toUpperCase() ?? "INCONNU";

            Color statusColor;
            IconData statusIcon;

            if (statut == "RUNNING") {
              statusColor = Colors.green;
              statusIcon = Icons.play_circle_fill;
            } else if (statut == "STOPPED") {
              statusColor = Colors.red;
              statusIcon = Icons.stop_circle;
            } else if (statut == "MAINTENANCE") {
              statusColor = Colors.orange;
              statusIcon = Icons.build_circle;
            } else {
              statusColor = Colors.grey;
              statusIcon = Icons.help_outline;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 27,
                    backgroundColor: statusColor.withOpacity(0.12),
                    child: Icon(
                      Icons.precision_manufacturing,
                      color: statusColor,
                      size: 30,
                    ),
                  ),

                  title: Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 4),

                            Expanded(child: Text(localisation)),
                          ],
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),

                            const SizedBox(width: 5),

                            Text(
                              statut,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    showMachineDetails(
                      id: id,
                      nom: nom,
                      localisation: localisation,
                      statut: statut,
                      statusColor: statusColor,
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // DÉTAIL MACHINE
  // ============================================================

  void showMachineDetails({
    required int id,
    required String nom,
    required String localisation,
    required String statut,
    required Color statusColor,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: statusColor.withOpacity(0.12),
                      child: Icon(
                        Icons.precision_manufacturing,
                        color: statusColor,
                        size: 34,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "Machine #$id",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text("Localisation"),
                  subtitle: Text(localisation),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle, color: statusColor, size: 18),
                  title: const Text("État"),
                  subtitle: Text(
                    statut,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      setState(() {
                        selectedPage = 2;
                        selectedProductionMachineId = id;
                      });

                      loadProduction(machineId: id);
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text("Voir les données de production"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PRODUCTION - API RÉELLE
  // ============================================================

  Widget productionPage() {
    if (!productionLoaded && !productionLoading && productionError == null) {
      Future.microtask(loadProduction);
    }

    if (productionLoading && productionData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productionError != null && productionData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Impossible de charger la production",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                productionError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    loadProduction(machineId: selectedProductionMachineId),
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final List<int> machineIds =
        productionData
            .map(
              (item) =>
                  int.tryParse((item as Map)['machineId']?.toString() ?? ''),
            )
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

    Map<String, dynamic>? latest;
    if (productionData.isNotEmpty) {
      latest = Map<String, dynamic>.from(productionData.first as Map);
    }

    final latestProduction = latest?['production']?.toString() ?? "0";

    final latestTemperature = double.tryParse(
      latest?['temperature']?.toString() ?? '',
    );

    final latestState = latest?['etat']?.toString().toUpperCase() ?? "INCONNU";

    return RefreshIndicator(
      onRefresh: () => loadProduction(machineId: selectedProductionMachineId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Production",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Données enregistrées par les machines"),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Actualiser",
                onPressed: productionLoading
                    ? null
                    : () => loadProduction(
                        machineId: selectedProductionMachineId,
                      ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<int?>(
            value: selectedProductionMachineId,
            decoration: const InputDecoration(
              labelText: "Filtrer par machine",
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Toutes les machines"),
              ),
              ...machineIds.map(
                (id) => DropdownMenuItem<int?>(
                  value: id,
                  child: Text(machineName(id)),
                ),
              ),
            ],
            onChanged: productionLoading
                ? null
                : (value) {
                    loadProduction(machineId: value);
                  },
          ),

          const SizedBox(height: 16),

          if (productionData.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bar_chart_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Aucune donnée de production",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedProductionMachineId == null
                          ? "Aucune donnée n'est encore enregistrée."
                          : "Aucune donnée pour ${machineName(selectedProductionMachineId!)}.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: productionSummaryCard(
                    title: "Production",
                    value: latestProduction,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: productionSummaryCard(
                    title: "Température",
                    value: latestTemperature == null
                        ? "--"
                        : "${latestTemperature.toStringAsFixed(1)} °C",
                    icon: Icons.thermostat,
                    color: latestTemperature != null && latestTemperature >= 70
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: productionSummaryCard(
                    title: "État",
                    value: latestState,
                    icon: latestState == "RUNNING"
                        ? Icons.play_circle_fill
                        : Icons.stop_circle,
                    color: latestState == "RUNNING" ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: productionSummaryCard(
                    title: "Mesures",
                    value: "${productionData.length}",
                    icon: Icons.history,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            const Text(
              "Historique des mesures",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...productionData.map((item) {
              final data = Map<String, dynamic>.from(item as Map);

              final machineId =
                  int.tryParse(data['machineId']?.toString() ?? '') ?? 0;

              final temperature = double.tryParse(
                data['temperature']?.toString() ?? '',
              );

              final production = data['production']?.toString() ?? "0";

              final etat = data['etat']?.toString().toUpperCase() ?? "INCONNU";

              final demandeAide = data['demandeAide'] == true;

              final createdAt = formatDateTime(data['createdAt']);

              final mqttTimestamp = formatDateTime(data['mqttTimestamp']);

              final Color stateColor = etat == "RUNNING"
                  ? Colors.green
                  : etat == "STOPPED"
                  ? Colors.red
                  : etat == "MAINTENANCE"
                  ? Colors.orange
                  : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: stateColor.withOpacity(0.12),
                            child: Icon(
                              Icons.precision_manufacturing,
                              color: stateColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  machineName(machineId),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: stateColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              etat,
                              style: TextStyle(
                                color: stateColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 26),

                      Row(
                        children: [
                          Expanded(
                            child: productionValue(
                              icon: Icons.inventory_2_outlined,
                              label: "Production",
                              value: "$production pièces",
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: productionValue(
                              icon: Icons.thermostat,
                              label: "Température",
                              value: temperature == null
                                  ? "--"
                                  : "${temperature.toStringAsFixed(1)} °C",
                              color: temperature != null && temperature >= 70
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Icon(
                            demandeAide
                                ? Icons.notification_important
                                : Icons.check_circle_outline,
                            size: 18,
                            color: demandeAide ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              demandeAide
                                  ? "Demande d'aide active"
                                  : "Aucune demande d'aide",
                              style: TextStyle(
                                color: demandeAide ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (mqttTimestamp != "--") ...[
                        const SizedBox(height: 10),
                        Text(
                          "Horodatage MQTT : $mqttTimestamp",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String machineName(int machineId) {
    for (final machine in machines) {
      final data = Map<String, dynamic>.from(machine as Map);

      final id = int.tryParse(data['id']?.toString() ?? '');

      if (id == machineId) {
        return data['nom']?.toString() ?? "Machine $machineId";
      }
    }

    return "Machine $machineId";
  }

  String formatDateTime(dynamic value) {
    if (value == null) {
      return "--";
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    final date = parsed.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return "${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} "
        "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
  }

  Widget productionSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productionValue({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALERTES - API RÉELLE
  // ============================================================

  Widget alertsPage() {
    if (!alertsLoaded && !alertsLoading && alertsError == null) {
      Future.microtask(loadAlerts);
    }

    if (alertsLoading && alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alertsError != null && alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Impossible de charger les alertes",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                alertsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => loadAlerts(machineId: selectedAlertMachineId),
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final List<int> machineIds =
        alerts
            .map(
              (item) =>
                  int.tryParse((item as Map)['machineId']?.toString() ?? ''),
            )
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

    final int activeCount = alerts.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['statut']?.toString().toUpperCase() == "ACTIVE";
    }).length;

    final int helpCount = alerts.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['type']?.toString().toUpperCase() == "DEMANDE_AIDE";
    }).length;

    final int temperatureCount = alerts.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['type']?.toString().toUpperCase() == "TEMPERATURE_ELEVEE";
    }).length;

    return RefreshIndicator(
      onRefresh: () => loadAlerts(machineId: selectedAlertMachineId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alertes",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Suivi des anomalies et demandes d'assistance"),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Actualiser",
                onPressed: alertsLoading
                    ? null
                    : () => loadAlerts(machineId: selectedAlertMachineId),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int?>(
            value: selectedAlertMachineId,
            decoration: const InputDecoration(
              labelText: "Filtrer par machine",
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Toutes les machines"),
              ),
              ...machineIds.map(
                (id) => DropdownMenuItem<int?>(
                  value: id,
                  child: Text(machineName(id)),
                ),
              ),
            ],
            onChanged: alertsLoading
                ? null
                : (value) {
                    loadAlerts(machineId: value);
                  },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: alertSummaryCard(
                  title: "Total",
                  value: "${alerts.length}",
                  icon: Icons.notifications_active_outlined,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: alertSummaryCard(
                  title: "Actives",
                  value: "$activeCount",
                  icon: Icons.warning_amber,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: alertSummaryCard(
                  title: "Aide",
                  value: "$helpCount",
                  icon: Icons.support_agent,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: alertSummaryCard(
                  title: "Température",
                  value: "$temperatureCount",
                  icon: Icons.thermostat,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (alerts.isEmpty)
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(26),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 58),
                    SizedBox(height: 12),
                    Text(
                      "Aucune alerte",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Aucune anomalie n'est enregistrée pour le filtre sélectionné.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Text(
              "Historique des alertes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...alerts.map((item) {
              final data = Map<String, dynamic>.from(item as Map);

              final int id = int.tryParse(data['id']?.toString() ?? '') ?? 0;
              final int machineId =
                  int.tryParse(data['machineId']?.toString() ?? '') ?? 0;

              final String type =
                  data['type']?.toString().toUpperCase() ?? "ALERTE";
              final String message =
                  data['message']?.toString() ?? "Aucun message";
              final String statut =
                  data['statut']?.toString().toUpperCase() ?? "INCONNU";
              final String dateHeure = formatDateTime(data['dateHeure']);

              Color alertColor;
              IconData alertIcon;
              String alertTitle;

              if (type == "TEMPERATURE_ELEVEE") {
                alertColor = Colors.red;
                alertIcon = Icons.thermostat;
                alertTitle = "Température élevée";
              } else if (type == "DEMANDE_AIDE") {
                alertColor = Colors.orange;
                alertIcon = Icons.support_agent;
                alertTitle = "Demande d'aide";
              } else if (type == "ARRET_MACHINE") {
                alertColor = Colors.red.shade700;
                alertIcon = Icons.stop_circle;
                alertTitle = "Arrêt machine";
              } else {
                alertColor = Colors.amber.shade800;
                alertIcon = Icons.warning_amber;
                alertTitle = type.replaceAll("_", " ");
              }

              final bool active = statut == "ACTIVE";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showAlertDetails(
                      id: id,
                      machineId: machineId,
                      type: alertTitle,
                      message: message,
                      statut: statut,
                      dateHeure: dateHeure,
                      color: alertColor,
                      icon: alertIcon,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: alertColor.withOpacity(0.12),
                              child: Icon(alertIcon, color: alertColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alertTitle,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    machineName(machineId),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statut,
                                style: TextStyle(
                                  color: active ? Colors.red : Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(message, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dateHeure,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget alertSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAlertDetails({
    required int id,
    required int machineId,
    required String type,
    required String message,
    required String statut,
    required String dateHeure,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Alerte #$id",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.precision_manufacturing),
                  title: const Text("Machine"),
                  subtitle: Text(machineName(machineId)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.message_outlined),
                  title: const Text("Message"),
                  subtitle: Text(message),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.circle,
                    color: statut == "ACTIVE" ? Colors.red : Colors.green,
                    size: 17,
                  ),
                  title: const Text("Statut"),
                  subtitle: Text(
                    statut,
                    style: TextStyle(
                      color: statut == "ACTIVE" ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text("Date et heure"),
                  subtitle: Text(dateHeure),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NOTIFICATIONS - API RÉELLE
  // ============================================================

  Widget notificationsPage() {
    if (!notificationsLoaded &&
        !notificationsLoading &&
        notificationsError == null) {
      Future.microtask(loadNotifications);
    }

    if (notificationsLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationsError != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Impossible de charger les notifications",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                notificationsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    loadNotifications(alertId: selectedNotificationAlertId),
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final sentCount = notifications.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['statut']?.toString().toUpperCase() == "ENVOYEE";
    }).length;

    final failedCount = notifications.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['statut']?.toString().toUpperCase() == "ECHEC";
    }).length;

    final alertIds =
        notifications
            .map(
              (item) =>
                  int.tryParse((item as Map)['alertId']?.toString() ?? ''),
            )
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

    return RefreshIndicator(
      onRefresh: () => loadNotifications(alertId: selectedNotificationAlertId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Historique des notifications envoyées par ProdMon"),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Actualiser",
                onPressed: notificationsLoading
                    ? null
                    : () => loadNotifications(
                        alertId: selectedNotificationAlertId,
                      ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<int?>(
            value: selectedNotificationAlertId,
            decoration: const InputDecoration(
              labelText: "Filtrer par alerte",
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Toutes les notifications"),
              ),
              ...alertIds.map(
                (id) => DropdownMenuItem<int?>(
                  value: id,
                  child: Text("Alerte #$id"),
                ),
              ),
            ],
            onChanged: notificationsLoading
                ? null
                : (value) => loadNotifications(alertId: value),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: notificationSummaryCard(
                  title: "Total",
                  value: "${notifications.length}",
                  icon: Icons.notifications_active_outlined,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: notificationSummaryCard(
                  title: "Envoyées",
                  value: "$sentCount",
                  icon: Icons.mark_email_read_outlined,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: notificationSummaryCard(
                  title: "Échecs",
                  value: "$failedCount",
                  icon: Icons.error_outline,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: notificationSummaryCard(
                  title: "Canal",
                  value: "EMAIL",
                  icon: Icons.email_outlined,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (notifications.isEmpty)
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: Colors.blue,
                      size: 58,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Aucune notification",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Aucune notification n'est enregistrée pour le filtre sélectionné.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Text(
              "Historique des notifications",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...notifications.map((item) {
              final data = Map<String, dynamic>.from(item as Map);

              final id = int.tryParse(data['id']?.toString() ?? '') ?? 0;
              final alertId =
                  int.tryParse(data['alertId']?.toString() ?? '') ?? 0;
              final destinataire =
                  data['destinataire']?.toString() ?? "Destinataire inconnu";
              final canal =
                  data['canal']?.toString().toUpperCase() ?? "INCONNU";
              final statut =
                  data['statut']?.toString().toUpperCase() ?? "INCONNU";
              final dateEnvoi = formatDateTime(data['dateEnvoi']);
              final createdAt = formatDateTime(data['createdAt']);

              final sent = statut == "ENVOYEE";
              final failed = statut == "ECHEC";
              final statusColor = sent
                  ? Colors.green
                  : failed
                  ? Colors.red
                  : Colors.orange;
              final statusIcon = sent
                  ? Icons.mark_email_read_outlined
                  : failed
                  ? Icons.error_outline
                  : Icons.schedule;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showNotificationDetails(
                      id: id,
                      alertId: alertId,
                      destinataire: destinataire,
                      canal: canal,
                      statut: statut,
                      dateEnvoi: dateEnvoi,
                      createdAt: createdAt,
                      color: statusColor,
                      icon: statusIcon,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.12),
                              child: Icon(statusIcon, color: statusColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Notification #$id",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Alerte #$alertId",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statut,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                destinataire,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.alternate_email,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Canal : $canal",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                dateEnvoi == "--"
                                    ? "Créée : $createdAt"
                                    : "Envoyée : $dateEnvoi",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget notificationSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showNotificationDetails({
    required int id,
    required int alertId,
    required String destinataire,
    required String canal,
    required String statut,
    required String dateEnvoi,
    required String createdAt,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notification #$id",
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Alerte #$alertId",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Destinataire"),
                  subtitle: Text(destinataire),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.send_outlined),
                  title: const Text("Canal"),
                  subtitle: Text(canal),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle, color: color, size: 17),
                  title: const Text("Statut"),
                  subtitle: Text(
                    statut,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text("Date d'envoi"),
                  subtitle: Text(dateEnvoi),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text("Créée le"),
                  subtitle: Text(createdAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // AJOUTER UN UTILISATEUR
  // ============================================================

  Future<void> showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedRole = "User";
    bool hidePassword = true;
    bool creating = false;

    final bool? created = await showDialog<bool>(
      context: context,
      barrierDismissible: !creating,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createUser() async {
              final username = usernameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();

              if (username.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez saisir le nom d'utilisateur."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (email.isEmpty || !email.contains("@")) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez saisir une adresse e-mail valide."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (password.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Le mot de passe doit contenir au moins 4 caractères.",
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setDialogState(() {
                creating = true;
              });

              final result = await ApiService.createUser(
                username: username,
                email: email,
                password: password,
                role: selectedRole,
              );

              if (!mounted || !dialogContext.mounted) return;

              if (result['success'] == true) {
                Navigator.of(dialogContext).pop(true);
                return;
              }

              setDialogState(() {
                creating = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message']?.toString() ??
                        "Impossible de créer l'utilisateur.",
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: Color(0xFFE53935)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ajouter un utilisateur",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Nom d'utilisateur",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Adresse e-mail",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!creating) {
                            createUser();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: creating
                                ? null
                                : () {
                                    setDialogState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: "Rôle",
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "User",
                            child: Text("Ouvrier / Opérateur"),
                          ),
                          DropdownMenuItem(
                            value: "Maintenance",
                            child: Text("Maintenance"),
                          ),
                          DropdownMenuItem(
                            value: "ChefProduction",
                            child: Text("Chef de production"),
                          ),
                          DropdownMenuItem(
                            value: "Directeur",
                            child: Text("Directeur"),
                          ),
                          DropdownMenuItem(
                            value: "Admin",
                            child: Text("Administrateur"),
                          ),
                        ],
                        onChanged: creating
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedRole = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Le compte sera créé actif. Lors de sa première "
                                "connexion, l'utilisateur créera son PIN personnel.",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text("Annuler"),
                ),
                FilledButton.icon(
                  onPressed: creating ? null : createUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                  ),
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(creating ? "Création..." : "Créer"),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Utilisateur créé avec succès dans PostgreSQL."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // UTILISATEURS - API RÉELLE
  // ============================================================

  Widget usersPage() {
    if (!usersLoaded && !usersLoading && usersError == null) {
      Future.microtask(loadUsers);
    }

    if (usersLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (usersError != null && users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Impossible de charger les utilisateurs",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                usersError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final int activeCount = users.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['isActive'] == true;
    }).length;

    final int adminCount = users.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return data['role']?.toString().toLowerCase() == "admin";
    }).length;

    final int maintenanceCount = users.where((item) {
      final data = Map<String, dynamic>.from(item as Map);
      final role = data['role']?.toString().toLowerCase() ?? "";
      return role == "maintenance" || role == "technicien";
    }).length;

    return RefreshIndicator(
      onRefresh: loadUsers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Utilisateurs",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Comptes enregistrés dans ProdMon"),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: usersLoading ? null : showCreateUserDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("Ajouter"),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: "Actualiser",
                onPressed: usersLoading ? null : loadUsers,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: userSummaryCard(
                  title: "Total",
                  value: "${users.length}",
                  icon: Icons.people_outline,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: userSummaryCard(
                  title: "Actifs",
                  value: "$activeCount",
                  icon: Icons.verified_user_outlined,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: userSummaryCard(
                  title: "Admins",
                  value: "$adminCount",
                  icon: Icons.admin_panel_settings_outlined,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: userSummaryCard(
                  title: "Maintenance",
                  value: "$maintenanceCount",
                  icon: Icons.engineering_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (users.isEmpty)
            Card(
              child: const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey, size: 60),
                    SizedBox(height: 14),
                    Text(
                      "Aucun utilisateur",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Text(
              "Liste des utilisateurs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...users.map((item) {
              final data = Map<String, dynamic>.from(item as Map);

              final int id = int.tryParse(data['id']?.toString() ?? '') ?? 0;

              final String username =
                  data['username']?.toString() ?? "Utilisateur";

              final String email =
                  data['email']?.toString() ?? "E-mail non défini";

              final String role = data['role']?.toString() ?? "User";

              final bool isActive = data['isActive'] == true;

              final String createdAt = formatDateTime(data['createdAt']);

              Color roleColor;
              IconData roleIcon;

              switch (role.toLowerCase()) {
                case "admin":
                  roleColor = Colors.red;
                  roleIcon = Icons.admin_panel_settings;
                  break;

                case "directeur":
                  roleColor = Colors.indigo;
                  roleIcon = Icons.business_center;
                  break;

                case "chefproduction":
                case "chef_production":
                case "chef production":
                  roleColor = Colors.teal;
                  roleIcon = Icons.supervisor_account;
                  break;

                case "maintenance":
                case "technicien":
                  roleColor = Colors.orange;
                  roleIcon = Icons.engineering;
                  break;

                case "user":
                case "operator":
                case "operateur":
                case "opérateur":
                  roleColor = Colors.blue;
                  roleIcon = Icons.precision_manufacturing_outlined;
                  break;

                default:
                  roleColor = Colors.grey;
                  roleIcon = Icons.person;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showUserDetails(
                      id: id,
                      username: username,
                      email: email,
                      role: role,
                      isActive: isActive,
                      createdAt: createdAt,
                      roleColor: roleColor,
                      roleIcon: roleIcon,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: roleColor.withOpacity(0.12),
                          child: Icon(roleIcon, color: roleColor, size: 29),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),

                              const SizedBox(height: 7),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Icon(
                                    isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),

                                  const SizedBox(width: 4),

                                  Text(
                                    isActive ? "Actif" : "Inactif",
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget userSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showUserDetails({
    required int id,
    required String username,
    required String email,
    required String role,
    required bool isActive,
    required String createdAt,
    required Color roleColor,
    required IconData roleIcon,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: roleColor.withOpacity(0.12),
                      child: Icon(roleIcon, color: roleColor, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Utilisateur #$id",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Adresse e-mail"),
                  subtitle: Text(email),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security, color: roleColor),
                  title: const Text("Rôle"),
                  subtitle: Text(
                    role,
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                  title: const Text("État du compte"),
                  subtitle: Text(
                    isActive ? "Actif" : "Inactif",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text("Créé le"),
                  subtitle: Text(createdAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // COMMANDES
  // MQTT + ENREGISTREMENT POSTGRESQL
  // ============================================================

  Future<void> sendMachineCommand({
    required String topic,
    required String payload,
    required String commande,
    required String label,
  }) async {
    if (commandSending) {
      return;
    }

    if (!mqttConnected || !mqttService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "MQTT est déconnecté. Impossible d'envoyer la commande.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      commandSending = true;
    });

    try {
      // 1. Créer d'abord la commande dans PostgreSQL.
      //    L'API retourne l'ID qui sera envoyé à l'ESP32.
      final result = await ApiService.createCommand(
        machineId: 1,
        utilisateurId: widget.userId,
        commande: commande,
        source: "MOBILE",
        statut: "ENVOYEE",
      );

      if (!mounted) return;

      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  "Impossible d'enregistrer la commande.",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Récupérer l'ID réel créé par PostgreSQL.
      final dynamic rawCommand = result['command'];

      if (rawCommand is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "La commande a été enregistrée, mais son identifiant est introuvable.",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final Map<String, dynamic> createdCommand = Map<String, dynamic>.from(
        rawCommand,
      );

      final int? commandId = int.tryParse(
        createdCommand['id']?.toString() ?? '',
      );

      if (commandId == null || commandId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Identifiant de commande invalide retourné par l'API.",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 3. Envoyer la commande structurée vers l'ESP32.
      //    Le topic/payload historiques restent dans la signature
      //    pour ne pas casser les boutons existants.
      mqttService.publishCommand(
        commandId: commandId,
        command: commande,
        machineId: 1,
      );

      // 4. Actualiser immédiatement l'historique.
      //    Le statut est ENVOYEE jusqu'à réception de l'ACK ESP32.
      await loadCommands(machineId: selectedCommandMachineId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$label : commande #$commandId envoyée à l'ESP32. "
            "En attente de l'ACK...",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi de la commande : $e"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          commandSending = false;
        });
      }
    }
  }

  Widget commandsPage() {
    if (!commandsLoaded && !commandsLoading && commandsError == null) {
      Future.microtask(loadCommands);
    }

    Color statusColor(String statut) {
      switch (statut.toUpperCase()) {
        case "EXECUTEE":
          return Colors.green;
        case "ENVOYEE":
          return Colors.blue;
        case "EN_ATTENTE":
          return Colors.orange;
        case "ECHEC":
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    IconData statusIcon(String statut) {
      switch (statut.toUpperCase()) {
        case "EXECUTEE":
          return Icons.check_circle;
        case "ENVOYEE":
          return Icons.send_outlined;
        case "EN_ATTENTE":
          return Icons.schedule;
        case "ECHEC":
          return Icons.error_outline;
        default:
          return Icons.help_outline;
      }
    }

    String commandLabel(String commande) {
      switch (commande.toUpperCase()) {
        case "GREEN_ON":
          return "Début du cycle";
        case "GREEN_OFF":
          return "Arrêt LED verte";
        case "YELLOW_ON":
          return "Besoin d'aide";
        case "YELLOW_OFF":
          return "Arrêt LED jaune";
        case "RED_ON":
          return "Fin du cycle";
        case "RED_OFF":
          return "Arrêt LED rouge";
        default:
          return commande;
      }
    }

    return RefreshIndicator(
      onRefresh: () => loadCommands(machineId: selectedCommandMachineId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Contrôle Machine 1",
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                mqttConnected
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: mqttConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mqttConnected ? "Connexion MQTT active" : "MQTT déconnecté",
                  style: TextStyle(
                    color: mqttConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (commandSending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "Utilisateur connecté : ${widget.username} • ID ${widget.userId}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  commandButton(
                    icon: Icons.play_arrow,
                    label: "Début du cycle",
                    color: Colors.green,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/green",
                        payload: "ON",
                        commande: "GREEN_ON",
                        label: "Début du cycle",
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  commandButton(
                    icon: Icons.stop,
                    label: "Arrêter LED verte",
                    color: Colors.grey.shade700,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/green",
                        payload: "OFF",
                        commande: "GREEN_OFF",
                        label: "Arrêt LED verte",
                      );
                    },
                  ),

                  const Divider(height: 32),

                  commandButton(
                    icon: Icons.support_agent,
                    label: "Besoin d'aide",
                    color: Colors.orange,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/yellow",
                        payload: "ON",
                        commande: "YELLOW_ON",
                        label: "Besoin d'aide",
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  commandButton(
                    icon: Icons.notifications_off_outlined,
                    label: "Arrêter LED jaune",
                    color: Colors.grey.shade700,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/yellow",
                        payload: "OFF",
                        commande: "YELLOW_OFF",
                        label: "Arrêt LED jaune",
                      );
                    },
                  ),

                  const Divider(height: 32),

                  commandButton(
                    icon: Icons.stop_circle_outlined,
                    label: "Fin du cycle",
                    color: Colors.red,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/red",
                        payload: "ON",
                        commande: "RED_ON",
                        label: "Fin du cycle",
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  commandButton(
                    icon: Icons.power_settings_new,
                    label: "Arrêter LED rouge",
                    color: Colors.grey.shade700,
                    onPressed: () {
                      sendMachineCommand(
                        topic: "prodmon/machine1/red",
                        payload: "OFF",
                        commande: "RED_OFF",
                        label: "Arrêt LED rouge",
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  "Historique des commandes",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: "Actualiser l'historique",
                onPressed: commandsLoading
                    ? null
                    : () => loadCommands(machineId: selectedCommandMachineId),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int?>(
            key: ValueKey(selectedCommandMachineId),
            initialValue: selectedCommandMachineId,
            decoration: const InputDecoration(
              labelText: "Filtrer l'historique par machine",
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Toutes les machines"),
              ),
              ...machines.map((machine) {
                final data = Map<String, dynamic>.from(machine as Map);
                final id = int.tryParse(data['id']?.toString() ?? '') ?? 0;
                final nom = data['nom']?.toString() ?? "Machine $id";

                return DropdownMenuItem<int?>(value: id, child: Text(nom));
              }),
            ],
            onChanged: commandsLoading
                ? null
                : (value) {
                    loadCommands(machineId: value);
                  },
          ),

          const SizedBox(height: 14),

          if (commandsLoading && commands.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (commandsError != null && commands.isEmpty)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 45),
                    const SizedBox(height: 10),
                    Text(commandsError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          loadCommands(machineId: selectedCommandMachineId),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
            )
          else if (commands.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.history, size: 55, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      "Aucune commande enregistrée",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      selectedCommandMachineId == null
                          ? "L'historique est vide."
                          : "Aucune commande pour cette machine.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ...commands.map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              final int machineId =
                  int.tryParse(data['machineId']?.toString() ?? '') ?? 0;
              final int utilisateurId =
                  int.tryParse(data['utilisateurId']?.toString() ?? '') ?? 0;
              final String commande =
                  data['commande']?.toString() ?? "INCONNUE";
              final String source = data['source']?.toString() ?? "--";
              final String statut =
                  data['statut']?.toString().toUpperCase() ?? "INCONNU";
              final String dateHeure = formatDateTime(data['dateHeure']);

              final color = statusColor(statut);
              final icon = statusIcon(statut);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commandLabel(commande),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Commande : $commande",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statut,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              machineName(machineId),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            dateHeure,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Utilisateur #$utilisateurId • Source : $source",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Le statut EXECUTEE est maintenant confirmé automatiquement "
                      "par l'accusé de réception MQTT envoyé par l'ESP32 après "
                      "l'exécution physique de la commande.",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFIL
  // ============================================================

  Widget profilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),

        Center(
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.red.shade50,
            child: const Icon(
              Icons.admin_panel_settings,
              color: Color(0xFFE53935),
              size: 60,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            widget.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 5),

        Center(
          child: Text(
            widget.email,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),

        const SizedBox(height: 10),

        Center(
          child: Chip(
            avatar: const Icon(Icons.admin_panel_settings, size: 18),
            label: Text(roleLabel),
          ),
        ),

        const SizedBox(height: 25),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Nom d'utilisateur"),
                subtitle: Text(widget.username),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Adresse e-mail"),
                subtitle: Text(widget.email),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.security),
                title: const Text("Rôle"),
                subtitle: Text(roleLabel),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Se déconnecter",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGETS ADMIN
  // ============================================================

  Widget welcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red.shade50,
              child: Icon(roleIcon, color: const Color(0xFFE53935), size: 34),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour ${widget.username}",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    widget.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    roleDescription,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget commandButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: mqttConnected && !commandSending ? onPressed : null,
        style: FilledButton.styleFrom(backgroundColor: color),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget pagePlaceholder({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 55),
            ),

            const SizedBox(height: 22),

            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),

            const SizedBox(height: 20),

            const Chip(label: Text("Connexion API à venir")),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAINTENANCE
// ============================================================

class MaintenancePage extends StatefulWidget {
  final String username;
  final String email;

  const MaintenancePage({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool alertsLoading = false;
  String? alertsError;
  List<dynamic> alerts = [];

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    if (alertsLoading) return;

    setState(() {
      alertsLoading = true;
      alertsError = null;
    });

    final result = await ApiService.getAlerts();

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic receivedAlerts = result['alerts'];

      setState(() {
        alerts = receivedAlerts is List ? receivedAlerts : [];
        alertsLoading = false;
      });
    } else {
      setState(() {
        alertsLoading = false;
        alertsError =
            result['message']?.toString() ??
            "Impossible de charger les alertes de maintenance.";
      });
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String formatDateTime(dynamic value) {
    if (value == null) return "--";

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final date = parsed.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return "${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} "
        "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
  }

  Color alertColor(String type) {
    final normalized = type.trim().toUpperCase();

    if (normalized.contains("TEMPERATURE")) return Colors.deepOrange;
    if (normalized.contains("AIDE") || normalized.contains("HELP")) {
      return Colors.orange;
    }
    if (normalized.contains("ARRET") || normalized.contains("STOP")) {
      return Colors.red;
    }

    return Colors.red;
  }

  IconData alertIcon(String type) {
    final normalized = type.trim().toUpperCase();

    if (normalized.contains("TEMPERATURE")) return Icons.thermostat;
    if (normalized.contains("AIDE") || normalized.contains("HELP")) {
      return Icons.support_agent;
    }
    if (normalized.contains("ARRET") || normalized.contains("STOP")) {
      return Icons.stop_circle_outlined;
    }

    return Icons.warning_amber_rounded;
  }

  List<Map<String, dynamic>> get normalizedAlerts {
    return alerts
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get activeAlerts {
    return normalizedAlerts.where((alert) {
      final statut =
          alert['statut']?.toString().trim().toUpperCase() ?? "ACTIVE";
      return statut == "ACTIVE" ||
          statut == "EN_ATTENTE" ||
          statut == "OUVERTE";
    }).toList();
  }

  void showAlertsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceAlertsPage(
          alerts: normalizedAlerts,
          onRefresh: loadAlerts,
        ),
      ),
    );
  }

  void showInterventionsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceInterventionsPage(
          alerts: activeAlerts,
          technicien: widget.username,
          onRefresh: loadAlerts,
        ),
      ),
    );
  }

  void showHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceHistoryPage(
          alerts: normalizedAlerts,
          onRefresh: loadAlerts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = activeAlerts.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          "ProdMon • Maintenance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Actualiser",
            onPressed: alertsLoading ? null : loadAlerts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            tooltip: "Déconnexion",
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadAlerts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.engineering, color: Colors.orange.shade800),
                ),
                title: Text(
                  "Bonjour ${widget.username}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(widget.email),
              ),
            ),
            const SizedBox(height: 14),
            if (alertsLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text("Chargement des données maintenance..."),
                      ),
                    ],
                  ),
                ),
              )
            else if (alertsError != null)
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.cloud_off, color: Colors.red),
                  title: const Text(
                    "Erreur de chargement",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(alertsError!),
                  trailing: IconButton(
                    onPressed: loadAlerts,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              )
            else
              Card(
                color: activeCount > 0
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                child: ListTile(
                  leading: Icon(
                    activeCount > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: activeCount > 0 ? Colors.orange : Colors.green,
                  ),
                  title: Text(
                    activeCount > 0
                        ? "$activeCount alerte(s) active(s)"
                        : "Aucune alerte active",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${normalizedAlerts.length} événement(s) enregistré(s) dans ProdMon",
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              "Maintenance",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.red),
                title: const Text(
                  "Alertes machines",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  alertsLoading
                      ? "Chargement..."
                      : "${normalizedAlerts.length} anomalie(s) enregistrée(s)",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: alertsLoading ? null : showAlertsPage,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: const Text(
                  "Interventions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  alertsLoading
                      ? "Chargement..."
                      : "$activeCount intervention(s) potentielle(s) à traiter",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: alertsLoading ? null : showInterventionsPage,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text(
                  "Historique",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Historique des événements de maintenance",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: alertsLoading ? null : showHistoryPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceAlertsPage extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final Future<void> Function() onRefresh;

  const MaintenanceAlertsPage({
    super.key,
    required this.alerts,
    required this.onRefresh,
  });

  @override
  State<MaintenanceAlertsPage> createState() => _MaintenanceAlertsPageState();
}

class _MaintenanceAlertsPageState extends State<MaintenanceAlertsPage> {
  late List<Map<String, dynamic>> alerts;

  @override
  void initState() {
    super.initState();
    alerts = List<Map<String, dynamic>>.from(widget.alerts);
  }

  String formatDateTime(dynamic value) {
    if (value == null) return "--";
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final date = parsed.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} "
        "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
  }

  Future<void> refresh() async {
    await widget.onRefresh();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Color typeColor(String type) {
    final normalized = type.toUpperCase();
    if (normalized.contains("TEMPERATURE")) return Colors.deepOrange;
    if (normalized.contains("AIDE") || normalized.contains("HELP")) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        title: const Text("Alertes machines"),
        actions: [
          IconButton(
            tooltip: "Actualiser",
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune alerte enregistrée.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final type = alert['type']?.toString() ?? "ALERTE";
                final message =
                    alert['message']?.toString() ?? "Anomalie détectée";
                final statut =
                    alert['statut']?.toString().toUpperCase() ?? "ACTIVE";
                final machineId = alert['machineId']?.toString() ?? "--";
                final date = formatDateTime(
                  alert['dateHeure'] ?? alert['createdAt'],
                );
                final color = typeColor(type);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(Icons.warning_amber_rounded, color: color),
                    ),
                    title: Text(
                      type.replaceAll("_", " "),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "$message\nMachine $machineId • $date\nStatut : $statut",
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class MaintenanceInterventionsPage extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final String technicien;
  final Future<void> Function() onRefresh;

  const MaintenanceInterventionsPage({
    super.key,
    required this.alerts,
    required this.technicien,
    required this.onRefresh,
  });

  @override
  State<MaintenanceInterventionsPage> createState() =>
      _MaintenanceInterventionsPageState();
}

class _MaintenanceInterventionsPageState
    extends State<MaintenanceInterventionsPage> {
  late List<Map<String, dynamic>> alerts;
  final Set<int> processingAlertIds = <int>{};

  @override
  void initState() {
    super.initState();
    alerts = List<Map<String, dynamic>>.from(widget.alerts);
  }

  String formatDateTime(dynamic value) {
    if (value == null) return "--";
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final date = parsed.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} "
        "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
  }

  Future<String?> askComment({
    required String title,
    required String resultat,
  }) async {
    String commentaire = "";

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: "",
            maxLines: 3,
            onChanged: (value) {
              commentaire = value;
            },
            decoration: const InputDecoration(
              labelText: "Commentaire (facultatif)",
              hintText: "Décrire brièvement l'intervention réalisée",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, commentaire.trim());
              },
              style: FilledButton.styleFrom(
                backgroundColor: resultat == "RESOLUE"
                    ? Colors.green
                    : Colors.red,
              ),
              child: const Text("Confirmer"),
            ),
          ],
        );
      },
    );
  }

  Future<void> refresh() async {
    await widget.onRefresh();

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> enregistrerIntervention({
    required Map<String, dynamic> alert,
    required String resultat,
  }) async {
    final int? alertId = int.tryParse(alert['id']?.toString() ?? '');

    if (alertId == null || alertId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Identifiant de l'alerte invalide."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool resolue = resultat == "RESOLUE";

    final commentaire = await askComment(
      title: resolue
          ? "Confirmer : panne résolue"
          : "Confirmer : panne majeure",
      resultat: resultat,
    );

    if (commentaire == null || !mounted) return;

    setState(() {
      processingAlertIds.add(alertId);
    });

    final result = await ApiService.createIntervention(
      alertId: alertId,
      technicien: widget.technicien,
      resultat: resultat,
      commentaire: commentaire.isEmpty ? null : commentaire,
    );

    if (!mounted) return;

    setState(() {
      processingAlertIds.remove(alertId);
    });

    if (result['success'] == true) {
      setState(() {
        alerts.removeWhere(
          (item) => int.tryParse(item['id']?.toString() ?? '') == alertId,
        );
      });

      await widget.onRefresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolue
                ? "Intervention enregistrée : panne résolue."
                : "Intervention enregistrée : panne majeure.",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: resolue ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                "Impossible d'enregistrer l'intervention.",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        title: const Text("Interventions"),
        actions: [
          IconButton(
            tooltip: "Actualiser",
            onPressed: () async {
              await widget.onRefresh();
              if (!mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 64,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Aucune intervention urgente",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Aucune alerte active ne nécessite actuellement une intervention.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final type = alert['type']?.toString() ?? "ALERTE";
                final message =
                    alert['message']?.toString() ?? "Anomalie détectée";
                final machineId = alert['machineId']?.toString() ?? "--";
                final int? alertId = int.tryParse(
                  alert['id']?.toString() ?? '',
                );
                final date = formatDateTime(
                  alert['dateHeure'] ?? alert['createdAt'],
                );
                final processing =
                    alertId != null && processingAlertIds.contains(alertId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFFF3E0),
                              child: Icon(Icons.build, color: Colors.orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Machine $machineId • ${type.replaceAll("_", " ")}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(message),
                        const SizedBox(height: 8),
                        Text(
                          "Détectée le $date",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Après vérification de la machine, enregistrez le résultat de l'intervention.",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (processing)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => enregistrerIntervention(
                                    alert: alert,
                                    resultat: "RESOLUE",
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text(
                                    "Panne résolue • Machine opérationnelle",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => enregistrerIntervention(
                                    alert: alert,
                                    resultat: "PANNE_MAJEURE",
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.report_problem),
                                  label: const Text(
                                    "Panne majeure • Machine indisponible",
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MaintenanceHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final Future<void> Function() onRefresh;

  const MaintenanceHistoryPage({
    super.key,
    required this.alerts,
    required this.onRefresh,
  });

  @override
  State<MaintenanceHistoryPage> createState() => _MaintenanceHistoryPageState();
}

class _MaintenanceHistoryPageState extends State<MaintenanceHistoryPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> interventions = [];

  @override
  void initState() {
    super.initState();
    loadInterventions();
  }

  String formatDateTime(dynamic value) {
    if (value == null) return "--";
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final date = parsed.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} "
        "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
  }

  Future<void> loadInterventions() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    final result = await ApiService.getInterventions();

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic received = result['interventions'];

      setState(() {
        interventions = received is List
            ? received
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error =
            result['message']?.toString() ??
            "Impossible de charger l'historique des interventions.";
      });
    }
  }

  Future<void> refresh() async {
    await widget.onRefresh();
    await loadInterventions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        title: const Text("Historique maintenance"),
        actions: [
          IconButton(
            tooltip: "Actualiser",
            onPressed: loading ? null : refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 60),
                    const SizedBox(height: 14),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: loadInterventions,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
            )
          : interventions.isEmpty
          ? const Center(
              child: Text("Aucune intervention de maintenance enregistrée."),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: interventions.length,
                itemBuilder: (context, index) {
                  final intervention = interventions[index];

                  final resultat =
                      intervention['resultat']?.toString().toUpperCase() ??
                      "INCONNU";
                  final resolue = resultat == "RESOLUE";

                  final machineId =
                      intervention['machineId']?.toString() ?? "--";
                  final alertId = intervention['alertId']?.toString() ?? "--";
                  final technicien =
                      intervention['technicien']?.toString() ?? "--";
                  final commentaire =
                      intervention['commentaire']?.toString().trim() ?? "";
                  final date = formatDateTime(intervention['dateIntervention']);

                  final color = resolue ? Colors.green : Colors.red;
                  final icon = resolue
                      ? Icons.check_circle_outline
                      : Icons.report_problem_outlined;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        resolue ? "Panne résolue" : "Panne majeure",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Machine $machineId • Alerte #$alertId\n"
                          "Technicien : $technicien • $date"
                          "${commentaire.isNotEmpty ? "\n$commentaire" : ""}",
                        ),
                      ),
                      isThreeLine: commentaire.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ============================================================
// USER
// ============================================================

class UserPage extends StatefulWidget {
  final String username;
  final String email;
  final String role;

  const UserPage({
    super.key,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final MQTTService mqttService = MQTTService();
  StreamSubscription<void>? mqttSubscription;

  bool mqttConnected = false;
  bool connectingMqtt = true;

  Map<String, dynamic>? derniereIntervention;
  bool interventionLoading = false;

  String get roleLabel {
    final normalizedRole = widget.role.trim().toLowerCase();

    if (normalizedRole == "user" ||
        normalizedRole == "operator" ||
        normalizedRole == "operateur" ||
        normalizedRole == "opérateur") {
      return "Ouvrier / Opérateur";
    }

    return widget.role;
  }

  @override
  void initState() {
    super.initState();

    mqttSubscription = mqttService.updates.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    connectMQTT();
    loadDerniereIntervention();
  }

  Future<void> connectMQTT() async {
    final result = await mqttService.connect();

    if (!mounted) return;

    setState(() {
      mqttConnected = result;
      connectingMqtt = false;
    });
  }

  Future<void> loadDerniereIntervention() async {
    if (interventionLoading) return;

    setState(() {
      interventionLoading = true;
    });

    final result = await ApiService.getInterventions();

    if (!mounted) return;

    if (result['success'] == true) {
      final dynamic received = result['interventions'];

      final List<Map<String, dynamic>> interventions = received is List
          ? received
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];

      setState(() {
        derniereIntervention = interventions.isNotEmpty
            ? interventions.first
            : null;
        interventionLoading = false;
      });
    } else {
      setState(() {
        interventionLoading = false;
      });
    }
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void showLineState() {
    final state = mqttService.machineState.toUpperCase();
    final bool running = state == "RUNNING";
    final bool stopped = state == "STOPPED";

    final Color stateColor = running
        ? Colors.green
        : stopped
        ? Colors.red
        : Colors.orange;

    final IconData stateIcon = running
        ? Icons.play_circle_fill
        : stopped
        ? Icons.stop_circle
        : Icons.help_outline;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "État de la ligne",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Card(
                  color: stateColor.withOpacity(0.08),
                  child: ListTile(
                    leading: Icon(stateIcon, color: stateColor, size: 38),
                    title: const Text(
                      "Machine 1",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      state,
                      style: TextStyle(
                        color: stateColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text("Connexion MQTT"),
                  subtitle: Text(
                    connectingMqtt
                        ? "Connexion..."
                        : mqttConnected
                        ? "Connectée"
                        : "Déconnectée",
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.thermostat, color: Colors.orange),
                  title: const Text("Température"),
                  subtitle: Text(
                    "${mqttService.temperature.toStringAsFixed(1)} °C",
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    mqttService.help
                        ? Icons.notification_important
                        : Icons.check_circle_outline,
                    color: mqttService.help ? Colors.red : Colors.green,
                  ),
                  title: const Text("Demande d'aide"),
                  subtitle: Text(
                    mqttService.help
                        ? "Demande d'aide active"
                        : "Aucune demande d'aide active",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showCurrentProduction() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService.getMachineDataByMachine(1);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                "Impossible de charger la production.",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dynamic received = result['data'];
    final List<dynamic> data = received is List ? received : [];

    Map<String, dynamic>? latest;
    if (data.isNotEmpty && data.first is Map) {
      latest = Map<String, dynamic>.from(data.first as Map);
    }

    final String production =
        latest?['production']?.toString() ?? "${mqttService.production}";
    final String etat =
        latest?['etat']?.toString().toUpperCase() ??
        mqttService.machineState.toUpperCase();
    final double? apiTemperature = double.tryParse(
      latest?['temperature']?.toString() ?? '',
    );
    final double temperature = apiTemperature ?? mqttService.temperature;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Production actuelle",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _workerStatCard(
                        title: "Production",
                        value: "$production pièces",
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _workerStatCard(
                        title: "Température",
                        value: "${temperature.toStringAsFixed(1)} °C",
                        icon: Icons.thermostat,
                        color: temperature >= 70 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: Icon(
                      etat == "RUNNING"
                          ? Icons.play_circle_fill
                          : Icons.stop_circle,
                      color: etat == "RUNNING" ? Colors.green : Colors.red,
                    ),
                    title: const Text("État de la machine"),
                    subtitle: Text(
                      etat,
                      style: TextStyle(
                        color: etat == "RUNNING" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${data.length} mesure(s) enregistrée(s) pour la Machine 1.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showHelpStatus() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Demande d'aide",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Card(
                  color: mqttService.help
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  child: ListTile(
                    leading: Icon(
                      mqttService.help
                          ? Icons.notification_important
                          : Icons.check_circle,
                      color: mqttService.help ? Colors.red : Colors.green,
                      size: 38,
                    ),
                    title: Text(
                      mqttService.help
                          ? "Demande active"
                          : "Aucune demande active",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      mqttService.help
                          ? "La Machine 1 demande actuellement une assistance."
                          : "Aucun besoin d'assistance n'est signalé actuellement.",
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.touch_app_outlined, color: Colors.orange),
                  title: Text("Signal d'aide opérateur"),
                  subtitle: Text(
                    "Le signal Help est transmis par le bouton d'aide relié à l'ESP32 et affiché ici en temps réel.",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _workerStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mqttSubscription?.cancel();
    mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        title: const Text(
          "ProdMon • Ouvrier",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            tooltip: "Déconnexion",
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await connectMQTT();
          await loadDerniereIntervention();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFFE53935),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bonjour ${widget.username}",
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleLabel,
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  mqttConnected ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: mqttConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  connectingMqtt
                      ? "Connexion MQTT..."
                      : mqttConnected
                      ? "Données temps réel connectées"
                      : "MQTT déconnecté",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (interventionLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text("Chargement du retour maintenance..."),
                    ],
                  ),
                ),
              )
            else if (derniereIntervention != null) ...[
              Builder(
                builder: (context) {
                  final intervention = derniereIntervention!;

                  final resultat =
                      intervention['resultat']?.toString().toUpperCase() ??
                      "INCONNU";

                  final bool resolue = resultat == "RESOLUE";

                  final String technicien =
                      intervention['technicien']?.toString() ?? "--";

                  final String commentaire =
                      intervention['commentaire']?.toString().trim() ?? "";

                  final String machineId =
                      intervention['machineId']?.toString() ?? "--";

                  final Color couleur = resolue ? Colors.green : Colors.red;

                  return Card(
                    color: resolue ? Colors.green.shade50 : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                resolue
                                    ? Icons.check_circle
                                    : Icons.report_problem,
                                color: couleur,
                                size: 32,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  resolue
                                      ? "Intervention terminée • Panne résolue"
                                      : "Panne majeure • Machine indisponible",
                                  style: TextStyle(
                                    color: couleur,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Machine $machineId",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 6),

                          Text("Technicien : $technicien"),

                          if (commentaire.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text("Commentaire : $commentaire"),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),
            ],
            const Text(
              "Production",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.factory_outlined, color: Colors.green),
                ),
                title: const Text(
                  "État de la ligne",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${mqttService.machineState.toUpperCase()} • Suivi temps réel",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: showLineState,
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.inventory_2_outlined, color: Colors.blue),
                ),
                title: const Text(
                  "Production actuelle",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${mqttService.production} pièce(s) • ${mqttService.temperature.toStringAsFixed(1)} °C",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: showCurrentProduction,
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.support_agent, color: Colors.orange),
                ),
                title: const Text(
                  "Demande d'aide",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  mqttService.help
                      ? "Demande active - assistance requise"
                      : "Aucune demande active",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: showHelpStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
