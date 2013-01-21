public class CustomTypeIterableBatch implements Database.Batchable<CustomType>
{
	public Iterable<CustomType> start(Database.BatchableContext bc)
	{
		return new CustomTypeIterable(2000);
	}
	
	public void execute(Database.BatchableContext bc, list<CustomType> scope)
	{
		for(CustomType item : scope)
			system.debug('§ '+item.stringValue);
	}
	
	public void finish(Database.BatchableContext bc) {}
	
	public class CustomTypeIterable implements Iterable<CustomType>
	{
		CustomTypeIterator iter;

		CustomTypeIterable(Integer iterations)
		{
			iter = new CustomTypeIterator();
			for(Integer i = 0; i < iterations; i++)
			{
				iter.itemList.add(new CustomType(i));
			}
		}

		public Iterator<CustomType> iterator()
		{
			return iter;
		}
	}

	public class CustomTypeIterator implements Iterator<CustomType>
	{
		List<CustomType> itemList = new List<CustomType>();		
		Integer index = 0;
		
		public boolean hasNext()
		{
			return index < itemList.size();
		}    

		public CustomType next()
		{
			if(hasNext())
				return itemList[index++];
			return null;
		}
    }

	public class CustomType
	{
		Integer integerValue;
		String stringValue;
		
		public CustomType(Integer i)
		{
			integerValue = i;
			stringValue = String.valueOf(i);
			stringValue = '0'.repeat(6-stringValue.length())+stringValue;
		}
	}
}