public class OpportunityLineItemService {
    
         public static void createAssests(List<OpportunityLineItem> newoppItemList){
             List<OpportunityLineItem> oppLineItemList = [select id,Opportunity.Name,ProductCode,Opportunity.StageName,Opportunity.AccountId,Opportunity.Amount,Opportunity.ContactId,Quantity,ListPrice,Product2Id from OpportunityLineItem where Id In:newoppItemList];
             List<Asset> assetList = new List<Asset>();
             for(OpportunityLineItem oli : oppLineItemList){
                 Asset ast = new Asset();
                 ast.Name=oli.Opportunity.Name;
                 ast.AccountId=oli.Opportunity.AccountId;
                 ast.ContactId=oli.Opportunity.ContactId;
                // ast.Price=oli.Opportunity.Amount * 10/100;
                 ast.Quantity=oli.Quantity;
                 ast.Product2Id=oli.Product2Id;
                 ast.SerialNumber=oli.ProductCode;
                 if(oli.Opportunity.StageName!='Closed Won' && oli.Opportunity.StageName!='Closed Lost'){
                      ast.Status='Registered';
                 }else   if(oli.Opportunity.StageName=='Closed Won'){
                      ast.Status='Purchased';
                 }
                
                  assetList.add(ast);  
             }
            
             if(!assetList.isEmpty()){
                 insert assetList;
             }
        }
}