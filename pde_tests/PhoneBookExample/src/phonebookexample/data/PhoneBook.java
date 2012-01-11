package phonebookexample.data;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class PhoneBook {
   
    private List<PhoneBookEntry> entries;
    
    public void addEntry(String name, String number) {
        addEntry(new PhoneBookEntry(name, number));
    }

    public void addEntry(PhoneBookEntry entry) {
        if (entries.contains(entry)) {
            throw new IllegalArgumentException("Cannot add a duplicate entry for " + entry);            
        }
        getEntries().add(entry);
    }
    
    public void removeEntry(String name, String number) {
        removeEntry(new PhoneBookEntry(name, number));
    }
    
    public void removeEntry(PhoneBookEntry entry) {
        if (getEntries().contains(entry)) {
            for (Iterator iter = getEntries().iterator(); iter.hasNext();) {
                PhoneBookEntry phoneBookEntry = (PhoneBookEntry) iter.next();
                if (entry.equals(phoneBookEntry)) {
                    iter.remove();
                }
            }
        }
    }

    public List<PhoneBookEntry> getEntries() {
        if (entries == null) {
            entries = new ArrayList<PhoneBookEntry>();
        }
        return entries;
    }
}
