import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:peercoin/providers/appsettings.dart';
import 'package:peercoin/tools/app_localizations.dart';
import 'package:peercoin/models/availablecoins.dart';
import 'package:peercoin/models/coinwallet.dart';
import 'package:peercoin/providers/activewallets.dart';
import 'package:peercoin/tools/app_routes.dart';
import 'package:peercoin/tools/auth.dart';
import 'package:peercoin/widgets/loading_indicator.dart';
import 'package:peercoin/widgets/new_wallet.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class WalletListScreen extends StatefulWidget {
  final bool fromColdStart;

  @override
  _WalletListScreenState createState() => _WalletListScreenState();
  WalletListScreen({this.fromColdStart = false});
}

class _WalletListScreenState extends State<WalletListScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _initial = true;
  late ActiveWallets _activeWallets;
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void didChangeDependencies() async {
    _activeWallets = Provider.of<ActiveWallets>(context);
    var _appSettings = Provider.of<AppSettings>(context, listen: false);
    await _appSettings.init(); //only required in home widget
    await _activeWallets.init();
    if (_initial) {
      setState(() {
        _initial = false;
      });
      controller = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this,
      );
      animation = Tween(begin: 88.0, end: 92.0).animate(controller);
      await controller.repeat(reverse: true);

      if (widget.fromColdStart == false) {
        if (_appSettings.authenticationOptions!['walletList']!) {
          await Auth.requireAuth(context, _appSettings.biometricsAllowed);
        }
      } else {
        //push to default wallet
        final values = await _activeWallets.activeWalletsValues;
        if (values.length == 1) {
          //only one wallet available, pushing to that one
          await Navigator.of(context).pushReplacementNamed(
            Routes.WalletHome,
            arguments: values[0],
          );
        } else if (values.length > 1) {
          //find default wallet
          final defaultWallet = values.firstWhereOrNull(
              (elem) => elem.letterCode == _appSettings.defaultWallet);
          if (defaultWallet != null) {
            await Navigator.of(context).pushReplacementNamed(
              Routes.WalletHome,
              arguments: defaultWallet,
            );
          }
        }
      }
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings_rounded),
          onPressed: () async {
            await Navigator.pushNamed(context, Routes.AppSettings);
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            key: Key('newWalletIconButton'),
            onPressed: () {
              if (_initial == false) {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return NewWalletDialog();
                    });
              }
            },
            icon: Icon(Icons.add_rounded),
          )
        ],
      ),
      body: _isLoading || _initial
          ? Center(
              child: LoadingIndicator(),
            )
          : Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: animation,
                    builder: (ctx, child) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 92,
                        ),
                        child: Container(
                          height: animation.value,
                          width: animation.value,
                          decoration: BoxDecoration(
                            color: Theme.of(context).shadowColor,
                            borderRadius:
                                BorderRadius.all(const Radius.circular(50.0)),
                            border: Border.all(
                              color: Theme.of(context).backgroundColor,
                              width: 2,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => Share.share(
                                'https://play.google.com/store/apps/details?id=com.coinerella.peercoin'),
                            child: Image.asset(
                              'assets/icon/ppc-logo.png',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Peercoin Wallet',
                      style: TextStyle(
                        letterSpacing: 1.4,
                        fontSize: 24,
                        color: Theme.of(context).backgroundColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  FutureBuilder(
                    future: _activeWallets.activeWalletsValues,
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Expanded(
                          child: Center(child: LoadingIndicator()),
                        );
                      }
                      var listData = snapshot.data! as List;
                      if (listData.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.instance
                                  .translate('wallets_none'),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).backgroundColor),
                            ),
                          ),
                        );
                      }
                      return Expanded(
                        child: ListView.builder(
                          itemCount: listData.length,
                          itemBuilder: (ctx, i) {
                            CoinWallet _wallet = listData[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              color: Theme.of(context).backgroundColor,
                              child: Column(
                                children: [
                                  InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        await Navigator.of(context)
                                            .pushReplacementNamed(
                                          Routes.WalletHome,
                                          arguments: _wallet,
                                        );
                                      },
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Image.asset(
                                              AvailableCoins()
                                                  .getSpecificCoin(_wallet.name)
                                                  .iconPath,
                                              width: 20),
                                        ),
                                        title: Text(
                                          _wallet.title,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            Text(
                                              (_wallet.balance / 1000000)
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              _wallet.letterCode,
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Theme.of(context).accentColor,
                                        ),
                                      )),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
