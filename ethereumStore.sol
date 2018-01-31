pragma solidity ^0.4.16;

/*

Copyright 2018 Sean Kenkeremath

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

contract EthereumStore {

    struct Item {
        string name;
        uint id;
        uint stock;
        uint price;
    }
    
    //TODO: is this struct necessary?
    struct Purchase {
        uint itemId;
    }
    
    mapping (address => Purchase[]) private purchases;
    mapping (uint => Item) private items;
    
    uint private itemIdCounter;

    address public storeOwner;
    
    function EthereumStore() public {
        storeOwner = msg.sender;
    }

    function addItemToStore(string name, uint stock, uint price) public {
        if (msg.sender != storeOwner) {
            //Only owner can add items to store
            return;
        }
        itemIdCounter++;
        
        Item memory item;
        item.id = itemIdCounter;
        item.name = name;
        item.stock = stock;
        item.price = price;

        items[item.id] = item;
    }
    
    function updateItemStock(uint itemId, uint newStock) public {
        if (msg.sender != storeOwner) {
            //Only owner can update stock
            return;
        }
        if (newStock < 0) {
            return;
        }
        items[itemId].stock = newStock;
    }
    
    //TODO: Optimize?
    function getForSaleItemIds() constant public returns (uint[]) {
        //first count
        uint numForSale = 0;
        for (uint i = 1; i <= itemIdCounter; i++){
            if (items[i].stock > 0) {
                numForSale++;
            }
        }
        
        uint[] memory itemIds  = new uint[](numForSale);
        
        //now actually add to array to return
        uint arrayIndex = 0;
        for (uint j = 1; j <= itemIdCounter; j++){
            if (items[j].stock > 0) {
                itemIds[arrayIndex] = items[j].id;
                arrayIndex++;
            }
        }
        
        return itemIds;
    }

    function purchaseItem(uint itemId) payable public {
        if (msg.sender == storeOwner) {
            //Owner cannot purchase from themselves
            return;
        }
        if (items[itemId].price > msg.value || items[itemId].stock < 1) {
            return;
        }

        Purchase memory purchase;
        purchase.itemId = itemId;
        
        purchases[msg.sender].push(purchase);
        items[itemId].stock = items[itemId].stock - 1;
    }
    
    //return IDs of all unredeemed purchases belong to user
    function getPurchaseItemIds(address customerAddress) public constant returns (uint[]) {
        uint[] memory purchaseIds = new uint[](purchases[customerAddress].length);
        for (uint i = 0; i<purchases[customerAddress].length; i++){
            purchaseIds[i] = purchases[customerAddress][i].itemId;
        }
        return purchaseIds;
    }

    function getItemName(uint itemId) public constant returns (string) {
        return items[itemId].name;
    }
    
    function getItemPrice(uint itemId) public constant returns (uint) {
        return items[itemId].price;
    }
    
    function getItemStock(uint itemId) public constant returns (uint) {
        return items[itemId].stock;
    }
    
    function transferPurchaseOwnership(uint purchaseId, address newOwner) public {
        transferPurchaseOwnershipInternal(purchaseId, msg.sender, newOwner);
    }
    
    //Just remove purchase from list to redeem
    function redeemPurchase(uint itemId) public {
        int indexToRemove = findPurchaseIndexInternal(itemId, msg.sender);
        if (indexToRemove < 0) {
            return;
        }
        removePurchaseInternal(uint(indexToRemove), msg.sender);
    }

    function transferPurchaseOwnershipInternal(uint itemId, address currentOwner, address newOwner) private {
        int indexToRemove = findPurchaseIndexInternal(itemId, currentOwner);
        if (indexToRemove < 0) {
            return;
        }
        
        purchases[newOwner].push(purchases[currentOwner][uint(indexToRemove)]);
        
        removePurchaseInternal(uint(indexToRemove), currentOwner);
    }
    
    function findPurchaseIndexInternal(uint itemId, address purchaseOwner) private constant returns (int) {
        int index = -1;
        for (uint i = 0; i<purchases[purchaseOwner].length; i++){
            if (purchases[purchaseOwner][i].itemId == itemId) {
                index = int(i);
            }
        }
        return index;
    }
    
    function removePurchaseInternal(uint indexToRemove, address customer) private {
        //resize original owner's array
        purchases[customer][indexToRemove] = purchases[customer][purchases[customer].length-1];
        purchases[customer].length = purchases[customer].length - 1;
    }
}