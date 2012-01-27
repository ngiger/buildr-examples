package phonebookexample.data;

public class PhoneBookEntry {
    private String name;
    private String number;
    
    public PhoneBookEntry(String name, String number) {
        setName(name);
        setNumber(number);
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        if (name == null) {
            throw new IllegalArgumentException("name cannot be null");
        }
        this.name = name;
    }

    public String getNumber() {
        return number;
    }

    public void setNumber(String number) {
        if (number == null) {
            throw new IllegalArgumentException("number cannot be null");
        }
        try {
            Long.parseLong(number);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Bad format for number " + number, e);
        }
        this.number = number;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if ((obj == null) || (obj.getClass() != this.getClass())) {
            return false;
        }
        PhoneBookEntry entry = (PhoneBookEntry)obj;
        return getName().equals(entry.getName()) && getNumber().equals(entry.getNumber());
    }

    @Override
    public int hashCode() {
        return getName().hashCode() + (17 * getNumber().hashCode());
    }

    @Override
    public String toString() {
        return "[PhoneBookEntry: name=" + getName() + ", number=" + getNumber() + "]";
    }
    
}
