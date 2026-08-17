
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await AppStore.instance.load(); runApp(const YokaTechPro()); }

class AppStore extends ChangeNotifier {
  static final AppStore instance = AppStore._();
  AppStore._();
  List<Map<String,dynamic>> products = [];
  List<Map<String,dynamic>> sales = [];
  List<Map<String,dynamic>> repairs = [];
  double expenses = 0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    products = _decode(p.getString('products')) ?? [
      {'name':'iPhone 15 Pro Max','category':'Phone','qty':10,'buy':125000.0,'sell':139900.0,'imei':'356789123456789'},
      {'name':'Samsung S24 Ultra','category':'Phone','qty':8,'buy':97000.0,'sell':109999.0,'imei':'356789123456780'},
      {'name':'20W PD Charger','category':'Accessory','qty':4,'buy':800.0,'sell':1299.0,'imei':''},
      {'name':'AirPods Pro 2','category':'Accessory','qty':12,'buy':62000.0,'sell':74900.0,'imei':''},
    ];
    sales = _decode(p.getString('sales')) ?? [];
    repairs = _decode(p.getString('repairs')) ?? [];
    expenses = p.getDouble('expenses') ?? 0;
    notifyListeners();
  }
  List<Map<String,dynamic>>? _decode(String? s) => s == null ? null : (jsonDecode(s) as List).map((e)=>Map<String,dynamic>.from(e)).toList();
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('products', jsonEncode(products));
    await p.setString('sales', jsonEncode(sales));
    await p.setString('repairs', jsonEncode(repairs));
    await p.setDouble('expenses', expenses);
    notifyListeners();
  }
  double get totalSales => sales.fold(0.0,(a,b)=>a+(b['total'] as num).toDouble());
  double get totalProfit => sales.fold(0.0,(a,b)=>a+(b['profit'] as num).toDouble()) - expenses;
  double get stockValue => products.fold(0.0,(a,b)=>a+(b['qty'] as num).toDouble()*(b['buy'] as num).toDouble());
  Future<void> addSale(String product, int qty, double total, double profit) async {
    final i=products.indexWhere((x)=>x['name']==product);
    if(i>=0) products[i]['qty']=(products[i]['qty'] as int)-qty;
    sales.add({'date':DateTime.now().toIso8601String(),'product':product,'qty':qty,'total':total,'profit':profit});
    await save();
  }
  Future<void> addRepair(String customer,String device,String issue,double total,double advance) async {
    repairs.insert(0,{'id':'RPR${10000+repairs.length+1}','date':DateTime.now().toIso8601String(),'customer':customer,'device':device,'issue':issue,'total':total,'advance':advance,'status':'Received'});
    await save();
  }
}

Future<void> mainApp() async { await AppStore.instance.load(); runApp(const YokaTechPro()); }

class YokaTechPro extends StatelessWidget {
  const YokaTechPro({super.key});
  @override Widget build(BuildContext c)=>AnimatedBuilder(
    animation: AppStore.instance, builder: (_,__)=>MaterialApp(
      debugShowCheckedModeBanner:false,title:'YOKA TECH',
      theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF070A12),
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF2563EB),brightness:Brightness.dark)),
      home:const Shell()));
}
class Shell extends StatefulWidget{const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{int i=0;final pages=const[Dashboard(),Stock(),Sales(),Repairs(),More()];@override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:pages[i]),bottomNavigationBar:NavigationBar(selectedIndex:i,onDestinationSelected:(v)=>setState(()=>i=v),destinations:const[NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Home'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'Stock'),NavigationDestination(icon:Icon(Icons.point_of_sale_outlined),label:'Sales'),NavigationDestination(icon:Icon(Icons.build_outlined),label:'Repair'),NavigationDestination(icon:Icon(Icons.more_horiz),label:'More')]));}

class Head extends StatelessWidget{final String title,sub;const Head(this.title,this.sub,{super.key});@override Widget build(BuildContext c)=>Row(children:[Container(width:48,height:48,decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),gradient:const LinearGradient(colors:[Color(0xFF2563EB),Color(0xFF7C3AED)])),child:const Center(child:Text('Y',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w800)),Text(sub,style:const TextStyle(color:Colors.white54))]))]);}

class Dashboard extends StatelessWidget{const Dashboard({super.key});@override Widget build(BuildContext c){final s=AppStore.instance;return ListView(padding:const EdgeInsets.all(18),children:[const Head('YOKA TECH','Pro Shop Management'),const SizedBox(height:8),const Text('Live business overview',style:TextStyle(color:Colors.white54)),const SizedBox(height:16),GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.5,children:[M('Today / Total Sales','LKR ${s.totalSales.toStringAsFixed(0)}',Icons.payments,Colors.green),M('Stock Value','LKR ${s.stockValue.toStringAsFixed(0)}',Icons.inventory,Colors.blue),M('Net Profit','LKR ${s.totalProfit.toStringAsFixed(0)}',Icons.trending_up,Colors.purple),M('Pending Repairs','${s.repairs.where((r)=>r['status']!='Delivered').length}',Icons.build,Colors.orange)]),const SizedBox(height:16),const Text('Quick Actions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[Action('New Sale',Icons.add_shopping_cart,()=>_sale(c)),Action('New Repair',Icons.build,()=>_repair(c)),Action('Add Expense',Icons.money_off,()=>_expense(c))]),const SizedBox(height:18),const Text('Recent Sales',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),...s.sales.take(5).map((x)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt)),title:Text(x['product']),subtitle:Text('${x['qty']} item(s)'),trailing:Text('LKR ${x['total']}'))))]);}}
class M extends StatelessWidget{final String a,b;final IconData i;final Color col;const M(this.a,this.b,this.i,this.col,{super.key});@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(i,color:col),Text(a,style:const TextStyle(color:Colors.white54,fontSize:12)),FittedBox(child:Text(b,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)))])));}

class Stock extends StatelessWidget{const Stock({super.key});@override Widget build(BuildContext c){final s=AppStore.instance;return ListView(padding:const EdgeInsets.all(18),children:[const Head('Stock','Live inventory & IMEI'),const SizedBox(height:14),FilledButton.icon(onPressed:()=>_addProduct(c),icon:const Icon(Icons.add),label:const Text('Add Product')),const SizedBox(height:12),...s.products.map((p)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.phone_android)),title:Text(p['name'],style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${p['category']} • Qty ${p['qty']}${p['imei'].toString().isNotEmpty?'\\nIMEI: ${p['imei']}':''}'),isThreeLine:true,trailing:Text('LKR ${p['sell']}',style:const TextStyle(fontWeight:FontWeight.bold)))))]);}}

class Sales extends StatelessWidget{const Sales({super.key});@override Widget build(BuildContext c){final s=AppStore.instance;return ListView(padding:const EdgeInsets.all(18),children:[const Head('Sales','Daily / Monthly / Yearly'),const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Total Sales',style:TextStyle(color:Colors.white54)),Text('LKR ${s.totalSales.toStringAsFixed(2)}',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text('Total Profit: LKR ${s.totalProfit.toStringAsFixed(2)}')]))),const SizedBox(height:14),...s.sales.map((x)=>Card(child:ListTile(title:Text(x['product']),subtitle:Text(x['date'].toString().substring(0,10)),trailing:Text('LKR ${x['total']}'))))]);}}

class Repairs extends StatelessWidget{const Repairs({super.key});@override Widget build(BuildContext c){final s=AppStore.instance;return ListView(padding:const EdgeInsets.all(18),children:[const Head('Repairs','Advance, balance & status'),const SizedBox(height:14),FilledButton.icon(onPressed:()=>_repair(c),icon:const Icon(Icons.add),label:const Text('New Repair')),const SizedBox(height:10),...s.repairs.map((r)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.build)),title:Text('${r['id']} • ${r['customer']}'),subtitle:Text('${r['device']} • ${r['issue']}\\nAdvance LKR ${r['advance']} • Balance LKR ${((r['total'] as num)-(r['advance'] as num)).toStringAsFixed(0)}'),isThreeLine:true,trailing:Text(r['status'],style:const TextStyle(fontWeight:FontWeight.bold)))))]);}}
class More extends StatelessWidget{const More({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Head('More','Reports & settings'),const SizedBox(height:14),...['Customers','Monthly Reports','Yearly Reports','Expenses','Suppliers','Staff & Permissions','Backup / Restore','Settings'].map((x)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.arrow_forward)),title:Text(x),trailing:const Icon(Icons.chevron_right))))]);}
class Action extends StatelessWidget{final String t;final IconData i;final VoidCallback f;const Action(this.t,this.i,this.f,{super.key});@override Widget build(BuildContext c)=>FilledButton.icon(onPressed:f,icon:Icon(i),label:Text(t));}

void _sale(BuildContext c){final s=AppStore.instance;if(s.products.isEmpty)return;String p=s.products.first['name'];final q=TextEditingController(text:'1');showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Sale'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(value:p,items:s.products.map((x)=>DropdownMenuItem(value:x['name'] as String,child:Text(x['name']))).toList(),onChanged:(v)=>p=v!),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{final n=int.tryParse(q.text)??1;final item=s.products.firstWhere((x)=>x['name']==p);final total=(item['sell'] as num).toDouble()*n;final profit=((item['sell'] as num)-(item['buy'] as num)).toDouble()*n;await s.addSale(p,n,total,profit);if(c.mounted)Navigator.pop(c);},child:const Text('Save Sale'))]));}
void _repair(BuildContext c){final a=TextEditingController(),d=TextEditingController(),i=TextEditingController(),t=TextEditingController(),adv=TextEditingController();showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Repair'),content:SingleChildScrollView(child:Column(children:[TextField(controller:a,decoration:const InputDecoration(labelText:'Customer')),TextField(controller:d,decoration:const InputDecoration(labelText:'Device')),TextField(controller:i,decoration:const InputDecoration(labelText:'Problem')),TextField(controller:t,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Total Cost')),TextField(controller:adv,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Advance'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{await AppStore.instance.addRepair(a.text,d.text,i.text,double.tryParse(t.text)??0,double.tryParse(adv.text)??0);if(c.mounted)Navigator.pop(c);},child:const Text('Save Repair'))]));}
void _addProduct(BuildContext c){final n=TextEditingController(),q=TextEditingController(text:'1'),b=TextEditingController(),s=TextEditingController(),imei=TextEditingController();showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Add Product'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Product')),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity')),TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Purchase Price')),TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Selling Price')),TextField(controller:imei,decoration:const InputDecoration(labelText:'IMEI / SKU'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{AppStore.instance.products.add({'name':n.text,'category':'Product','qty':int.tryParse(q.text)??1,'buy':double.tryParse(b.text)??0,'sell':double.tryParse(s.text)??0,'imei':imei.text});await AppStore.instance.save();if(c.mounted)Navigator.pop(c);},child:const Text('Save'))]));}
void _expense(BuildContext c){final x=TextEditingController();showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Add Expense'),content:TextField(controller:x,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{AppStore.instance.expenses+=double.tryParse(x.text)??0;await AppStore.instance.save();if(c.mounted)Navigator.pop(c);},child:const Text('Save'))]));}
