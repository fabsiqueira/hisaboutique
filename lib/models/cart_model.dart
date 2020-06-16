import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:hbapp/datas/cart_product.dart';
import 'package:hbapp/models/user_model.dart';
import 'package:scoped_model/scoped_model.dart';

class CartModel extends Model{
  UserModel user;

  List<CartProduct> products = [];

  bool get isLoading => false;

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

void _loadCartItems()async {
  QuerySnapshot query = await Firestore.instance.collection("users").document(user.firebaseUser.uid).
  collection("cart").getDocuments();

  products = query.documents.map((doc) => CartProduct.fromDocument(doc)).toList();

  notifyListeners();
}


}