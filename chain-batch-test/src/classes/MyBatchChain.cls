public with sharing class MyBatchChain implements Database.Batchable<sObject>
{
	Integer m_phaseIndex;
	Integer LAST_PHASE_INDEX = 2;
	
	public static Id startChain()
	{
		return Database.executeBatch(new MyBatchChain());
	}
	
	MyBatchChain()
	{
		this(0);
	}
	
	MyBatchChain(Integer phaseIndex)
	{
		m_phaseIndex = phaseIndex;
	}
	
	public Database.querylocator start(Database.BatchableContext BC)
	{
		if(m_phaseIndex==0)
			return Database.getQueryLocator('select id from Account where AnnualRevenue > 50000000 and (not AccountNumber like \'R-%\')');
		else if(m_phaseIndex==1)
			return Database.getQueryLocator('select id from Contact where Account.AccountNumber like \'R-%\'');
		else if(m_phaseIndex==2)
			return Database.getQueryLocator('select id from Case where Account.AccountNumber like \'R-%\'');
		else
			throw new MyBatchChainException('Bad index');
    }

	public void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		if(m_phaseIndex==0)
			phaseOne(scope);			
		else if(m_phaseIndex==1)
			phaseTwo(scope);			
		else if(m_phaseIndex==2)
			phaseThree(scope);			
		else
			throw new MyBatchChainException('Bad index');
	}

	void phaseOne(List<SObject> scope)
	{
		List<Account> items = [select AccountNumber from Account where Id in :scope];
		for(Account item : items)
			item.AccountNumber = 'R-'+item.AccountNumber;
		update items;
	}
	
	void phaseTwo(List<SObject> scope)
	{
		List<Contact> items = [select id from Contact where Id in :scope];
		for(Contact item : items)
			item.Description = 'Contact Needs Analysis';
		update items;
	}
	
	void phaseThree(List<SObject> scope)
	{
		List<Case> items = [select id from Case where Id in :scope];
		for(Case item : items)
			item.Description='Case Needs Analysis';
		update items;
	}

	public void finish(Database.BatchableContext BC)
	{
		if(m_phaseIndex < LAST_PHASE_INDEX)
		{
			Database.executeBatch(new MyBatchChain(m_phaseIndex+1));
		}
		else
		{
			// do finish
		}
	}
	
	public class MyBatchChainException extends Exception {}
	
	@IsTest(SeeAllData=false)
	static void myBatchChainTest()
	{
		List<Account> accounts = new List<Account>{
			new Account(Name='Acc1',AnnualRevenue=60000000,AccountNumber='A1'),
			new Account(Name='Acc2',AnnualRevenue=10000000,AccountNumber='A2'),
			new Account(Name='Acc3',AnnualRevenue=70000000,AccountNumber='A3')
		};
		insert accounts;
		
		List<Contact> contacts = new List<Contact>{
			new Contact(AccountId=accounts[0].id, LastName='Con1', Description='Con1'),
			new Contact(AccountId=accounts[1].id, LastName='Con2', Description='Con2'),
			new Contact(AccountId=accounts[2].id, LastName='Con3', Description='Con3')
		};
		insert contacts;
		
		List<Case> cases = new List<Case>{
			new Case(AccountId=accounts[0].id, Description='Case1'),
			new Case(AccountId=accounts[1].id, Description='Case2'),
			new Case(AccountId=accounts[2].id, Description='Case3')
		};
		insert cases;
		
		Test.startTest();
		MyBatchChain.startChain();
		Test.stopTest();
		
		// Check phase 0 results		
		Set<Id> accountIdSet = new Map<Id,Account>(accounts).keySet();
		Map<Id,Account> accountResults = new Map<Id,Account>([select AccountNumber from Account where id in:accountIdSet]);
		system.assertEquals(3,accountResults.size());
		system.assertEquals('R-A1',accountResults.get(accounts[0].id).AccountNumber);
		system.assertEquals('A2',accountResults.get(accounts[1].id).AccountNumber);
		system.assertEquals('R-A3',accountResults.get(accounts[2].id).AccountNumber);

		// Check phase 1 results		
		Set<Id> contactIdSet = new Map<Id,Contact>(contacts).keySet();
		Map<Id,Contact> contactResults = new Map<Id,Contact>([select Description from Contact where id in:contactIdSet]);
		system.assertEquals(3,contactResults.size());
		system.assertEquals('Contact Needs Analysis',contactResults.get(contacts[0].id).Description);
		system.assertEquals('Con2',contactResults.get(contacts[1].id).Description);
		system.assertEquals('Contact Needs Analysis',contactResults.get(contacts[2].id).Description);

		// Check phase 2 results		
		Set<Id> caseIdSet = new Map<Id,Case>(cases).keySet();
		Map<Id,Case> caseResults = new Map<Id,Case>([select Description from Case where id in:caseIdSet]);
		system.assertEquals(3,caseResults.size());
		system.assertEquals('Case Needs Analysis',caseResults.get(cases[0].id).Description);
		system.assertEquals('Case2',caseResults.get(cases[1].id).Description);
		system.assertEquals('Case Needs Analysis',caseResults.get(cases[2].id).Description);
	}
	
}