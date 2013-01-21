/* 
 * Batch job to delete ALL of the records in an object - it will chain jobs together until no records remain - use with caution!
 */

public with sharing virtual class ChainBatchDelete implements Database.Batchable<sObject>
{
	/*
	 * static
	 */
	 
	static final Integer BATCH_SIZE = 2000;
	static final Integer QUERY_LIMIT = 10000000;

	public static void executeNow(String objectName)
	{
		Database.executeBatch(new ChainBatchDelete(objectName), BATCH_SIZE);
	}
	
	/*
	 * Instance
	 */

	ChainBatchDelete() {}
	
	ChainBatchDelete(String objectName)
	{
		m_objectName = objectName;
	}
	
	String m_objectName;

	public Database.querylocator start(Database.BatchableContext BC)
	{
		return m_objectName==null ? null : Database.getQueryLocator('select Id from ' + m_objectName + ' LIMIT ' + QUERY_LIMIT);
    }
	
	public void execute(Database.BatchableContext BC, List<sObject> scope)
	{
    	doDelete(scope);
    	doEmptyRecycleBin(scope);
	}
	
	public void finish(Database.BatchableContext BC)
	{
		if(!Database.query('select id from ' + m_objectName + ' limit 1').isEmpty())
			Database.executeBatch(new ChainBatchDelete(m_objectName), BATCH_SIZE);
	}

	// Database methods - to be overridden in test context
	virtual void doDelete(List<sObject> items) { Database.delete(items); }
	virtual void doEmptyRecycleBin(List<sObject> items) { Database.emptyRecycleBin(items); }

	/*
	 * Tests
	 */

	// Test classes
	
	class TChainBatchDelete extends ChainBatchDelete
	{
		TChainBatchDelete() { }
		TChainBatchDelete(String objectName) { super(objectName); }
		List<sObject> m_deletedItems, m_emptiedItems;
		override void doDelete(List<sObject> items) { m_deletedItems = items; }
		override void doEmptyRecycleBin(List<sObject> items) { m_emptiedItems = items; }
	}

	// Test methods
	
	@IsTest
	static void testStart()
	{
		TChainBatchDelete instance;
		Database.querylocator result;
		
		instance = new TChainBatchDelete();
		system.assertEquals(null,instance.start(null));

		instance = new TChainBatchDelete(null);
		system.assertEquals(null,instance.start(null));

		instance = new TChainBatchDelete('Account');
		result = instance.start(null);
		system.assertEquals('select Id from Account LIMIT 10000000',result.getQuery());
	}

	@IsTest
	static void testExecuteDelete()
	{
		TChainBatchDelete instance;
		
		List<sObject> recs = new List<sObject>();
		for(Integer i=0; i<3; i++) 
			recs.add(new Account(Id=testGetId(Account.SObjectType),Name='TestAccount'));
		
		instance = new TChainBatchDelete('Account');
		instance.execute(null,recs);
		assertSobjectListEquals(recs,instance.m_deletedItems);
		assertSobjectListEquals(recs,instance.m_emptiedItems);
	}


	static void assertSobjectListEquals(List<SObject> recsA, List<SObject> recsB)
	{
		if(recsA==null || recsB==null)
		{
			system.assert(recsA==null && recsB==null);
		}
		else
		{
			system.assert(recsA.size()==recsB.size(), recsA.size() + ' <> ' + recsB.size());
			Iterator<SObject> iterB = recsB.iterator();
			for(SObject itemA : recsA)
			{
				sObject itemB = iterB.next();
				system.assertEquals(itemA, itemB, itemA + ' <> ' + itemB);
			}
		}
	}

	static Integer t_num = 1;
	static String testGetId(Schema.SObjectType sot)
	{
		String result = String.valueOf(t_num++);
		while(result.length()<12)
			result = '0'+result;
		return sot.getDescribe().getKeyPrefix() + result;
	}
}