import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:hbapp/datas/cart_product.dart';
import 'package:hbapp/models/user_model.dart';
import 'package:scoped_model/scoped_model.dart';

class CartModel extends Model{
  UserModel user;

  List<CartProduct> products = [];
  String couponCode;
  int discountPercentage = 0;

  bool isLoading = false;

  CartModel(this.user){
    if (user.isLoggedIn())
      _loadCartItems();
  }

  //acessando o cart model de qlqr lugar
  static CartModel of (BuildContext context)=>
      ScopedModel.of<CartModel>(context);

  void addCartItem(CartProduct cartProduct){
    products.add(cartProduct);

    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").add(cartProduct.toMap())
    .then((doc){
      cartProduct.cid = doc.documentID;
    });

    notifyListeners();

  }
  void removeCartItem(CartProduct cartProduct){

    Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("cart").document(cartProduct.cid).delete();

    products.remove(cartProduct);

    notifyListeners();

  }
  //decrementar a qtde de produtos
 void decProduct(CartProduct cartProduct){
    cartProduct.quantity--;
    Firestore.instance.collection("users").document(user.firebaseUser.uid).
    collection("cart").document(cartProduct.cid).updateData(cartProduct.toMap());
    notifyListeners();

 }
void incProduct(CartProduct cartProduct){
  cartProduct.quantity++;
  Firestore.instance.collection("users").document(user.firebaseUser.uid).
  collection("cart").document(cartProduct.cid).updateData(cartProduct.toMap());
  notifyListeners();

}
void setCoupon(String couponcode, int discountPercentage){
    this.couponCode = couponCode;
    this.discountPercentage = discountPercentage;
}
void updatePrices(){
    notifyListeners();
}
double getProductsPrice(){
    double price = 0.0;
    for(CartProduct c in products){
      if(c.productData != null)
        price += c.quantity * c.productData.price;

    }
    return price;

}
double getDiscount(){
    return getProductsPrice() * discountPercentage/100;

}
double getShipPrices(){
    return 9.99;
}

Future<String> finishOrder() async{
    if(products.length == 0) return null ;
    isLoading = true;
    notifyListeners();
    double productsPrice = getProductsPrice();
    double shipPrice = getShipPrices();
    double discountPrice = getDiscount();
    //criando referencia para que o usuario acesse
    DocumentReference refOrder = await Firestore.instance.collection("orders").add({
      "clientId": user.firebaseUser.uid,
      "products": products.map((cartProducts)=>cartProducts.toMap()).toList(),
      "shipPrice": shipPrice,
      "productsPrice": productsPrice,
      "discount": discountPrice,
      "totalPrice": productsPrice - discountPrice +shipPrice,
      "status": 1
    }
    );
    //salvando order Id dentro do usuário
    await Firestore.instance.collection("users").document(user.firebaseUser.uid).collection("orders").document(refOrder.documentID).setData({
      "orderId": refOrder.documentID
    }
    );
    //remover os produtos do carrinho
  QuerySnapshot query  = await Firestore.instance.collection("users").document(user.firebaseUser.uid)
      .collection("cart").getDocuments();
  //selecionando cada produto para deletar
    for(DocumentSnapshot doc in query.documents){
    doc.reference.delete();
  }
  products.clear();
  couponCode = null;
  discountPercentage = 0;

  isLoading = false;
  notifyListeners();

  return refOrder.documentID;
}


void _loadCartItems()async {
  QuerySnapshot query = await Firestore.instance.collection("users").document(user.firebaseUser.uid).
  collection("cart").getDocuments();

  products = query.documents.map((doc) => CartProduct.fromDocument(doc)).toList();

  notifyListeners();

}


}