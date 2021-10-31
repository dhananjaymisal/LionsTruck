public class ContractSubscriptionUpgrade {
    @AuraEnabled
    // Method to Upgrade the Contract.
    public static String upgradeConSub(String ContractId,String ProductId){
        messages msgobj = new messages();
        string message='';
        string warning='';
        system.debug('ContractId=='+ContractId);
        system.debug('ProductId==='+ProductId);
        List<Contract> conOppIdLst=[select Id,Opportunity__c,EndDate from Contract where Id=:ContractId AND status!='Draft' AND Contract.Opportunity__r.StageName='Closed Won'];
        system.debug('conOppIdLst==='+conOppIdLst);
        if(!conOppIdLst.isEmpty()){
            List<OpportunityLineItem> oppItems = [select id,name,Product2.ProductCode,Product2.SubscriptionPeriod__c from OpportunityLineItem where opportunityId=:conOppIdLst[0].Opportunity__c];
            system.debug('oppIte'+oppItems);
            if(!oppItems.isEmpty()){
                Boolean haveSubSmall=false;
                Boolean haveSubLarge=false;
                for(OpportunityLineItem oppLine : oppItems){
                    if(oppLine.Product2.SubscriptionPeriod__c=='1 year'){
                        haveSubSmall=true;
                    }else if(oppLine.Product2.ProductCode=='5 year'){
                        haveSubLarge = true;
                    }
                }
                system.debug('haveSubLarge=='+haveSubLarge);
                system.debug('haveSubLarge=='+haveSubSmall);
                if(haveSubSmall){
                    if(String.isNotBlank(ContractId) && String.isBlank(ProductId)){
                        return message = getProducts(oppItems[0].Product2.ProductCode);
                    }else if(String.isNotBlank(ContractId) && String.isNotBlank(ProductId)){
                        return message = updateOppstatus(conOppIdLst[0].Opportunity__c,ProductId);   
                    }
                }else if(haveSubLarge){
                    
                    if(conOppIdLst[0].EndDate > system.today().addDays(30)){
                        msgobj.name='Warning';
                        msgobj.description='Your Subscription is on maximum upgrade';
                        message = JSON.serialize(msgobj);
                    }
                    if(conOppIdLst[0].EndDate <= system.today().addDays(30)){
                        if(String.isNotBlank(ContractId) && String.isBlank(ProductId)){
                            return message = getProducts(oppItems[0].Product2.ProductCode);
                        }else if(String.isNotBlank(ContractId) && String.isNotBlank(ProductId)){
                            return message = updateOppstatus(conOppIdLst[0].Opportunity__c,ProductId);
                        }
                    }   
                }
            }else{
                msgobj.name='Warning';
                msgobj.description='you do not have any subscriptions';
                message = JSON.serialize(msgobj);
            }
        }else{
            msgobj.name='Warning';
            msgobj.description='Looks Opportunity is (upgraded or still open).';
            message = JSON.serialize(msgobj);
        }
        return message; 
    }
    
    // Method To Submit for Approval
    public static String updateOppstatus(String oppId,String ProductId){ 
        system.debug('oppId==='+oppId);
         system.debug('ProductId==='+ProductId);
        messages msgobj = new messages();
        string message='';
        string warning='';
        List<ProcessInstance> proLst =[SELECT CompletedDate,Status,TargetObjectId FROM ProcessInstance WHERE Status = 'Pending' AND TargetObjectId=:oppId];
        system.debug('proLst=='+proLst);
        if(!proLst.isEmpty()){
            msgobj.name='Warning';
            msgobj.description='Approval in process';
            return message = JSON.serialize(msgobj);
        }else{
            system.debug('in else');
            system.debug('oppId=='+oppId);
            system.debug('ProductId=='+ProductId);
            Opportunity op = new Opportunity(Id=oppId,ApprovalStatus__c ='Pending for Approval',RequestedProducttoUpgrade__c=ProductId);
            update op;
            system.debug('op=='+op.Id);
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Subscription Submitted for approval');
            approvalRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            approvalRequest.setObjectId(op.Id);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        }
        msgobj.name='Success';
        msgobj.description='Your Subscription submitted successfully';
        return message = JSON.serialize(msgobj);
        
    }
    
    //Method to get Existing Upgradable Products.
    public static string getProducts(String ProductCode){
        system.debug('ProductCode==='+ProductCode);
        system.debug('inisde get products');
        string productsJSONResult = '';
        string message='';
        UpgradableProductsResult objproducts = new UpgradableProductsResult();
        List<Updgradableproducts> UprodList = new List<Updgradableproducts>();
        messages msgobj = new messages();
        system.debug('ProductCode=='+ProductCode);
        List<product2> prodLst= [SELECT Id,IsActive,Name,ProductCode,Createddate,SubscriptionPeriod__c,IsUpgradable__c FROM Product2 where IsUpgradable__c=true AND IsActive=true AND SubscriptionPeriod__c='1 Year' AND ProductCode=:ProductCode];
        system.debug('prodLst=='+prodLst);
        if(!prodLst.isEmpty()){
            for(Product2 prodobj :prodLst){
                Updgradableproducts Uprod = new Updgradableproducts();
                Uprod.upgradableproductRecord = prodobj;
                Uprod.createdDate = prodobj.CreatedDate;
                Uprod.isUpgradable=prodobj.IsUpgradable__c;
                Uprod.productname=prodobj.Name;
                Uprod.productID=prodobj.Id;
                Uprod.productSubscription=prodobj.SubscriptionPeriod__c;
                Uprod.productcode=prodobj.productCode;
                Uprod.isActive=prodobj.IsActive;
                uprod.isSelected=false;
                UprodList.add(Uprod);       
            }
            system.debug('UprodList==='+UprodList);
            objproducts.upgradabledList = UprodList;
            productsJSONResult = JSON.serialize(objproducts);
            msgobj.name='';
            msgobj.description=productsJSONResult;
            
        }else{
         msgobj.name='Warning';
        msgobj.description='No Upgradable product found in this Contract.';
        return message = JSON.serialize(msgobj);
            
        }
        system.debug('JSON.serialize(objproducts);'+JSON.serialize(objproducts));
        return message = JSON.serialize(objproducts);
    }
    public class UpgradableProductsResult {
        public List<Updgradableproducts> upgradabledList {get;set;}
    }
    
    // Wrapper to handle Products.
    public class Updgradableproducts {
        public Product2 upgradableproductRecord {get;set;}
        public DateTime createdDate {get;set;}
        public Boolean isUpgradable {get;set;}
        public String productName {get;set;}
        public String productID{get;set;}
        public string productCode{get;set;}
        public string productSubscription{get;set;}
        public boolean isActive{get;set;}
        public boolean isSelected{get;set;}
    }
    
    // Wrapper to Handle messages.
    public class messages{
        public string name;
        public string description;
    }
    
}