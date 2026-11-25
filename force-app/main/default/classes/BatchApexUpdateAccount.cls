global class BatchApexUpdateAccount implements database.Batchable<sObject> {

    global database.querylocator start(database.BatchableContext bc){
    
    return database.getquerylocator('Select rating from Account');
}

public static void execute(database.BatchableContext bc,List<Account> scope){

    for(Account acc:scope){
        acc.rating='Hot';
    }
    update scope;
}

public static void finish(database.BatchableContext bc){
    AsyncApexjob idd=[Select Id from AsyncApexjob where Id=:bc.getjobId()];
}

}