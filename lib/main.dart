import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vtm_tablet/providers/alert_provider.dart';
import 'package:vtm_tablet/providers/data_provider.dart';
import 'package:vtm_tablet/providers/report_provider.dart';
import 'package:vtm_tablet/providers/wakelock_provider.dart';
import 'package:vtm_tablet/services/udp_service.dart';
import 'package:vtm_tablet/services/mqtt_service.dart';
import 'package:vtm_tablet/ui/tabs/analog_pages.dart';
import 'package:vtm_tablet/ui/tabs/can_bus_tab.dart';
import 'package:vtm_tablet/ui/tabs/config_tab.dart';
import 'package:vtm_tablet/ui/tabs/digital_tab.dart';
import 'package:vtm_tablet/ui/tabs/fault_report_tab.dart';
import 'package:vtm_tablet/ui/tabs/core_log_tab.dart';
import 'package:vtm_tablet/ui/tabs/karotiyer_tab.dart';
import 'package:vtm_tablet/ui/tabs/shift_report_tab.dart';
import 'package:vtm_tablet/ui/tabs/dtc_tab.dart';
import 'package:vtm_tablet/ui/tabs/home_tab.dart';
import 'package:vtm_tablet/ui/tabs/report_tab.dart';
// import 'ui/tabs/debug_view_tab.dart';
import 'package:flutter/services.dart';
import 'package:vtm_tablet/providers/config_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vtm_tablet/services/update_service.dart';
import 'package:vtm_tablet/ui/widgets/update_dialog.dart';
import 'package:vtm_tablet/services/kiosk_service.dart';
import 'package:vtm_tablet/ui/widgets/kiosk_guard.dart';

/// Kiosk kabugu, geri tusu geldiginde acik bir diyalog var mi diye buraya bakar.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class NoStretchScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

    // 1. ConfigurationProvider'ı oluşturuyoruz.
  final configProvider = ConfigurationProvider();
  
  // 2. Ayarların diskten yüklenmesini BEKLİYORUZ.
  await configProvider.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        // 1. Merkezi UdpService'i tek bir instance olarak oluşturup sağlıyoruz.
        Provider<UdpService>(
          create: (_) => UdpService(),
          dispose: (_, service) => service.dispose(),
        ),
        // 2. MQTT Servisi (İnternetsiz çalıştığı için devredışı bırakıldı)
        Provider<MqttService>(
          create: (_) {
            final mqtt = MqttService();
            // mqtt.connect(); // arka planda bağlanmasını kapattık
            return mqtt;
          },
          lazy: true, // Uygulama açılır açılmaz bağlanmasın
          dispose: (_, service) => service.disconnect(),
        ),
        // 2. Diğer Provider'ları bu servisi kullanarak oluşturuyoruz.
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProxyProvider<UdpService, DataProvider>(
          create: (context) => DataProvider(context.read<UdpService>()),
          update: (_, service, previous) => DataProvider(service),
        ),
        ChangeNotifierProxyProvider2<UdpService, MqttService, ReportProvider>(
          create: (context) => ReportProvider(
            context.read<UdpService>(),
            context.read<MqttService>(),
          ),
          update: (context, udpService, mqttService, previous) => ReportProvider(
            udpService,
            mqttService,
          ),
        ),
        ChangeNotifierProvider<WakelockProvider>(
          create: (_) => WakelockProvider(),
          lazy: false, // Uygulama başlar başlamaz çalışsın
        ),
        ChangeNotifierProxyProvider2<DataProvider, ConfigurationProvider, AlertProvider>(
        create: (context) => AlertProvider(
          context.read<DataProvider>(),
          context.read<ConfigurationProvider>().appConfig,
        ),
        // DEĞİŞİKLİK: Yeni bir provider oluşturmak yerine, 'previous' yani
        // mevcut olanı güncelliyoruz.
        update: (_, dataProvider, configProvider, previous) =>
            previous!..updateDependencies(dataProvider, configProvider.appConfig),
      ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTM-16',
      debugShowCheckedModeBanner: false,
      scrollBehavior: NoStretchScrollBehavior(),
      navigatorKey: appNavigatorKey,
      // Kiosk kabugu Navigator'in DISINDA duruyor: acik diyaloglar dahil her
      // seyin uzerinde kalsin ve kenar kaydirmalarini her durumda yakalasin.
      builder: (context, child) => KioskGuard(
        navigatorKey: appNavigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'VTM-16'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meanings
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _updateTimer;
  bool _isChecking = false;

  late PageController _pageController;
  final List<String> _pageTitles = [
    'Rapor Gönder',
    '',
    'Makine Verileri 1/3',
    'Makine Verileri 2/3',
    'Makine Verileri 3/3',
    'Motor Verileri',
    'Arıza Raporu',
    'Karot Bilgileri',
    'Karotiyer Bilgileri',
    'Vardiya Raporu',
    'Hata Kodları (DTC)',
    'Konfigürasyon',
    // 'Debug Ekranı',
  ];

  final List<Widget> _pages = [
    ReportTab(),
    const HomeTab(),
    const AnalogTabPage1(),
    const AnalogTabPage2(),
    const DigitalTab(),
    const CanBusTab(),
    const FaultReportTab(),
    const CoreLogTab(),
    const KarotiyerTab(),
    const ShiftReportTab(),
    const DtcTab(),
    const ConfigTab(),
    // const DebugViewTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Lifecycle observer
    _pageController = PageController();
    // Merkezi UDP servisini başlatıyoruz
    context.read<UdpService>().startListener();
    context.read<DataProvider>().startListener();

    // SADECE WiFi bağlantısı değişince güncelleme kontrolü yap
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.wifi)) {
        // İnternet tam hazır olsun diye 3 saniye bekle
        Future.delayed(const Duration(seconds: 3), _checkForUpdate);
      }
    });
    // Uygulama açılışında widget hazır olduktan sonra kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    // Her 5 dakikada bir periyodik kontrol (bağlantı değişmese bile)
    _updateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkForUpdate(),
    );
  }

  Future<void> _checkForUpdate() async {
    if (_isChecking) return;
    
    // YENİ: Kontrol öncesi anlık olarak sadece WiFi'de miyiz diye bak
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.wifi)) {
      return; // WiFi yoksa (örneğin sadece SIM kart varsa) sessizce iptal et
    }

    _isChecking = true;
    try {
      final result = await UpdateService.checkUpdate();
      if (result.available && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(remoteBuildNumber: result.remoteBuild),
        );
      }
    } catch (_) {
      // Bağlantı yoksa veya kontrol başarısız olursa sessizce geç
    } finally {
      if (mounted) {
        _isChecking = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Lifecycle observer kaldır
    _connectivitySubscription?.cancel();
    _updateTimer?.cancel();
    _pageController.dispose();
    //context.read<DataProvider>().stopUdpListener();
    //WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final dp = context.read<DataProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Uygulama arka plana geçti
      dp.setAppBackground(true);
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana döndü
      dp.setAppBackground(false);
    }
  }

  // NOT: Eski "Uygulamadan Cik" diyalogu kaldirildi. Kiosk modunda uygulamadan
  // cikisin TEK yolu kenar kaydirmasi/geri tusu ile acilan yetkili parolasidir
  // (bkz. lib/ui/widgets/kiosk_guard.dart). SystemNavigator.pop cagiran bir yol
  // birakilirsa kilit anlamsiz hale gelir.

  void _showGlobalAlertDialog(BuildContext context, PopUpData popupData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final level = popupData.level;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                level == PopUpAlertLevel.critical ? Icons.error : Icons.warning,
                color: level == PopUpAlertLevel.critical ? Colors.red : Colors.orange,
                size: 52,
              ),
              const SizedBox(width: 10),
              Text(
                level == PopUpAlertLevel.critical ? 'KRİTİK ALARM' : 'UYARI',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(popupData.message, style: const TextStyle(fontSize: 32)),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam', style: TextStyle(fontSize: 24)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Pop-up kapandıktan sonra provider'daki durumu temizle
      context.read<AlertProvider>().clearPopup();
    });
  }

  @override
  Widget build(BuildContext context) {

        // YENİ: AlertProvider'ı dinliyoruz
    final alertProvider = context.watch<AlertProvider>();
    final newPopup = alertProvider.newPopupToShow;
    
    // EĞER gösterilecek yeni bir pop-up varsa...
    if (newPopup != null) {
      // Build metodu bittikten sonra diyalogu göster.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGlobalAlertDialog(context, newPopup);
      });
    }

    // Geri tusu/jesti uygulamayi ASLA kapatmamali. Android tarafi bu olayi
    // zaten yakaliyor; bu PopScope ikinci hattir: olay bir sekilde Flutter'a
    // ulasirsa da cikis engellenir ve yetkili parolasi ekrani acilir.
    return PopScope(
      canPop: !KioskService.isSupported,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) KioskGuard.requestExitPrompt();
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false, // KLAVYE AÇILDIĞINDA EKRANI DARALTMA!
      appBar: AppBar(
        // ✅ DEĞİŞİKLİK: Sol tarafa sabit başlık eklendi
        leadingWidth: 500, // Metnin sığması için genişliği ayarlıyoruz
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Align(
            //alignment: Alignment.centerLeft,
            child: Text(
              'MTA TEMEL SONDAJ TAKİP PROGRAMI',
              style: TextStyle(
                color: Color.fromARGB(255, 4, 100, 100),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        
        // ✅ DEĞİŞİKLİK: Ortalanmış dinamik başlık
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        backgroundColor: Colors.white,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Selector<WakelockProvider, bool>(
              selector: (_, provider) => provider.isWakelockActive,
              builder: (context, isCharging, _) {
                return Tooltip(
                  message: isCharging ? 'Cihaz Şarj Oluyor' : 'Cihaz Pilde',
                  child: Icon(
                    isCharging ? Icons.power : Icons.power_off,
                    color: isCharging ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Selector<DataProvider, ConnectionStatus>(
              selector: (_, provider) => provider.connectionStatus,
              builder: (context, status, _) {
                final isConnected = status == ConnectionStatus.connected;
                return Tooltip(
                  message: isConnected ? 'Bağlantı Aktif' : 'Bağlantı Kesildi',
                  child: Icon(
                    isConnected ? Icons.link : Icons.link_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          //const PersistentAlertBanner(),
          const Divider(thickness: 1, height: 1, color: Colors.grey),
          Expanded(
            child: Row(
              children: [
            //     NavigationRail(
            //       selectedIndex: _selectedIndex,
            //       onDestinationSelected: (int index) {
            //         // 3. İkona tıklandığında hem state'i güncelliyor hem de PageView'ı o sayfaya atlatıyoruz.
            //         setState(() {
            //           _selectedIndex = index;
            //         });
            //         _pageController.jumpToPage(index);
            //       },
            //       labelType: NavigationRailLabelType.none,
            //       //backgroundColor: const Color(0xFF343A40),
            //       indicatorColor: Colors.blue.shade100,
            //       unselectedIconTheme: IconThemeData(
            //         color: Colors.grey.shade600,
            //       ),
            //       // Seçili ikon rengini tema rengi yapıyoruz
            //       selectedIconTheme: IconThemeData(
            //         color: Theme.of(context).primaryColor,
            //       ),
            // destinations: const <NavigationRailDestination>[
            //   NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Anasayfa')), // YENİ
            //   NavigationRailDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed), label: Text('Makine Göstergeleri 1/3')),
            //   NavigationRailDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed), label: Text('Makine Göstergeleri 2/3')),
            //   NavigationRailDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: Text('Makine Göstergeleri 3/3')),
            //   NavigationRailDestination(icon: Icon(Icons.memory_outlined), selectedIcon: Icon(Icons.memory), label: Text('Motor Dataları')),
            //   NavigationRailDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: Text('Hatalar')),
            //   NavigationRailDestination(icon: Icon(Icons.note_alt_outlined), selectedIcon: Icon(Icons.note_alt), label: Text('Rapor')),
            //   NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Ayarlar')),
            //   NavigationRailDestination(icon: Icon(Icons.bug_report_outlined), selectedIcon: Icon(Icons.bug_report), label: Text('Debug')),
            // ],
            //       // trailing: Expanded(
            //       //   child: Align(
            //       //     alignment: Alignment.bottomCenter,
            //       //     child: Padding(
            //       //       padding: const EdgeInsets.only(bottom: 20.0),
            //       //       child: IconButton(
            //       //         icon: const Icon(
            //       //           Icons.exit_to_app,
            //       //           color: Colors.redAccent,
            //       //           size: 30,
            //       //         ),
            //       //         tooltip: 'Uygulamadan Çık',
            //       //         onPressed: _showExitDialog,
            //       //       ),
            //       //     ),
            //       //   ),
            //       // ),
            //     ),

                const VerticalDivider(thickness: 1, width: 1),

                Expanded(
                  // 4. Sayfaları göstermek için PageView kullanıyoruz.
                  child: PageView(
                    physics: const ClampingScrollPhysics(),
                    controller: _pageController,
                    // Sayfaları children olarak veriyoruz
                    children: _pages,
                    // Kullanıcı sayfayı kaydırdığında (swipe) bu fonksiyon çalışır.
                    onPageChanged: (int index) {
                      // Kaydırma işlemi bittiğinde NavigationRail'in seçili ikonunu güncelliyoruz.
                      setState(() {
                        _selectedIndex = index;
                      });
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
