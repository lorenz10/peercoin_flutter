import 'package:flutter/material.dart';
import 'package:peercoin/providers/activewallets.dart';
import 'package:peercoin/tools/app_localizations.dart';
import 'package:peercoin/models/wallettransaction.dart';
import 'package:intl/intl.dart';
import 'package:peercoin/tools/app_routes.dart';
import 'package:peercoin/widgets/wallet_balance_header.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:provider/provider.dart';

class TransactionList extends StatefulWidget {
  final List<WalletTransaction> _walletTransactions;
  final _wallet;
  final _connectionState;
  TransactionList(
      this._walletTransactions, this._wallet, this._connectionState);

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String _filterChoice = 'all';

  void _handleSelect(String newChoice) {
    setState(() {
      _filterChoice = newChoice;
    });
  }

  String resolveAddressDisplayName(String address) {
    final result = context
        .read<ActiveWallets>()
        .getLabelForAddress(widget._wallet.name, address);
    if (result != '') return '$result';
    return address;
  }

  Widget renderConfirmationIndicator(WalletTransaction tx) {
    if (tx.confirmations == -1) {
      return Text(
        'X',
        textScaleFactor: 0.9,
        style: TextStyle(color: Colors.red),
      );
    }
    return tx.broadCasted == false
        ? Text(
            '?',
            textScaleFactor: 0.9,
            style: TextStyle(color: Theme.of(context).accentColor),
          )
        : CircularStepProgressIndicator(
            selectedStepSize: 5,
            unselectedStepSize: 5,
            totalSteps: 6,
            currentStep: tx.confirmations,
            width: 20,
            height: 20,
            selectedColor: Theme.of(context).primaryColor,
            unselectedColor:
                Theme.of(context).unselectedWidgetColor.withOpacity(0.5),
            stepSize: 4,
            roundedCap: (_, __) => true,
          );
  }

  @override
  Widget build(BuildContext context) {
    var _reversedTx = widget._walletTransactions
        .where((element) => element.timestamp != -1) //filter "phantom" tx
        .toList()
        .reversed
        .toList();
    var _filteredTx = _reversedTx;
    if (_filterChoice != 'all') {
      _filteredTx = _reversedTx
          .where((element) => element.direction == _filterChoice)
          .toList();
    }

    return Stack(
      children: [
        WalletBalanceHeader(widget._connectionState, widget._wallet),
        widget._walletTransactions
                .where((element) =>
                    element.timestamp != -1) //don't count "phantom" tx
                .isEmpty
            ? Center(
                child: Text(
                AppLocalizations.instance.translate('transactions_none'),
                style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).backgroundColor),
              ))
            : GestureDetector(
                onHorizontalDragEnd: (dragEndDetails) {
                  if (dragEndDetails.primaryVelocity! < 0) {
                    //left swipe
                    if (_filterChoice == 'in') {
                      _handleSelect('all');
                    } else if (_filterChoice == 'all') {
                      _handleSelect('out');
                    }
                  } else if (dragEndDetails.primaryVelocity! > 0) {
                    //right swipe
                    if (_filterChoice == 'out') {
                      _handleSelect('all');
                    } else if (_filterChoice == 'all') {
                      _handleSelect('in');
                    }
                  }
                },
                child: ListView.builder(
                  itemCount: _filteredTx.length + 1,
                  itemBuilder: (_, i) {
                    if (i > 0) {
                      return Container(
                        color: Theme.of(context).primaryColor,
                        child: Card(
                          child: ListTile(
                            horizontalTitleGap: 32.0,
                            onTap: () => Navigator.of(context)
                                .pushNamed(Routes.Transaction, arguments: [
                              _filteredTx[i - 1],
                              ModalRoute.of(context)!.settings.arguments
                            ]),
                            leading: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 500),
                                    child: renderConfirmationIndicator(
                                      _filteredTx[i - 1],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('d. MMM').format(
                                        _filteredTx[i - 1].timestamp != 0
                                            ? DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    _filteredTx[i - 1]
                                                            .timestamp! *
                                                        1000)
                                            : DateTime.now()),
                                    style: TextStyle(
                                      fontWeight:
                                          _filteredTx[i - 1].timestamp != 0
                                              ? FontWeight.w500
                                              : FontWeight.w300,
                                    ),
                                    textScaleFactor: 0.8,
                                  )
                                ]),
                            title: Center(
                              child: Text(
                                _filteredTx[i - 1].txid,
                                overflow: TextOverflow.ellipsis,
                                textScaleFactor: 0.9,
                              ),
                            ),
                            subtitle: Center(
                              child: Text(
                                resolveAddressDisplayName(
                                    _filteredTx[i - 1].address),
                                overflow: TextOverflow.ellipsis,
                                textScaleFactor: 1,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  getText(_filteredTx[i - 1]),
                                  style: TextStyle(
                                    fontWeight:
                                        _filteredTx[i - 1].timestamp != 0
                                            ? FontWeight.bold
                                            : FontWeight.w300,
                                    color: getColor(_filteredTx[i - 1]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (i == 0 &&
                        widget._walletTransactions.isNotEmpty) {
                      return Column(
                        children: [
                          SizedBox(height: 130),
                          Wrap(
                            spacing: 8.0,
                            children: <Widget>[
                              ChoiceChip(
                                backgroundColor:
                                    Theme.of(context).backgroundColor,
                                selectedColor: Theme.of(context).shadowColor,
                                visualDensity: VisualDensity(
                                    horizontal: 0.0, vertical: -4),
                                label: Container(
                                    child: Text(
                                  AppLocalizations.instance
                                      .translate('transactions_in'),
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                  ),
                                )),
                                selected: _filterChoice == 'in',
                                onSelected: (_) => _handleSelect('in'),
                              ),
                              ChoiceChip(
                                backgroundColor:
                                    Theme.of(context).backgroundColor,
                                selectedColor: Theme.of(context).shadowColor,
                                visualDensity: VisualDensity(
                                    horizontal: 0.0, vertical: -4),
                                label: Text(
                                    AppLocalizations.instance
                                        .translate('transactions_all'),
                                    style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                    )),
                                selected: _filterChoice == 'all',
                                onSelected: (_) => _handleSelect('all'),
                              ),
                              ChoiceChip(
                                backgroundColor:
                                    Theme.of(context).backgroundColor,
                                selectedColor: Theme.of(context).shadowColor,
                                visualDensity: VisualDensity(
                                    horizontal: 0.0, vertical: -4),
                                label: Text(
                                    AppLocalizations.instance
                                        .translate('transactions_out'),
                                    style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                    )),
                                selected: _filterChoice == 'out',
                                onSelected: (_) => _handleSelect('out'),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
      ],
    );
  }

  //Tempura
  String getText(WalletTransaction tx){
    if(tx.isTimestampTx) return 'File';
    if(tx.direction == 'out'){
      return '-'+(tx.value / 1000000).toString();
    }else{
      return '+'+(tx.value / 1000000).toString();
    }
  }
  //Tempura
  Color getColor(WalletTransaction tx){
    if(tx.isTimestampTx) return Colors.blue;
    if(tx.direction == 'out'){
      return Theme.of(context).errorColor;
    }else{
      return Theme.of(context).bottomAppBarColor;
    }
  }
}
