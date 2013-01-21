public class IntegerIterableBatch implements Database.Batchable<Integer>
{
	public Iterable<Integer> start(Database.BatchableContext bc)
	{
		return new IntegerIterable(2000);
	}
	
	public void execute(Database.BatchableContext bc, list<Integer> scope)
	{
		for(Integer item : scope)
			system.debug('§ '+item);
	}
	
	public void finish(Database.BatchableContext bc) {}
	
	public class IntegerIterable implements Iterable<Integer>
	{
		IntegerIterator iter;

		IntegerIterable(Integer iterations)
		{
			iter = new IntegerIterator(iterations);
		}

		public Iterator<Integer> iterator()
		{
			return iter;
		}
	}

	public class IntegerIterator implements Iterator<Integer>
	{
		Integer max; 		
		Integer index = 0;
		
		IntegerIterator(Integer iterations)
		{
			max = iterations;
		}
		
		public boolean hasNext()
		{
			return index < max;
		}    

		public Integer next()
		{
			return index++;
		}
    }
}