package phonebookexample.dialogs;

import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.dialogs.TitleAreaDialog;
import org.eclipse.jface.window.Window;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;

import phonebookexample.data.PhoneBook;
import phonebookexample.data.PhoneBookEntry;


public class PhoneBookEditorDialog extends TitleAreaDialog {
    PhoneBook phoneBook;
    
    Composite phoneBookComposite;    
    Table phoneBookEntriesTable;    
    Button newEntryButton;
    Button removeEntryButton;
    Button editEntryButton;
    
    public PhoneBookEditorDialog(Shell parent, PhoneBook phoneBook) {
        super(parent);
        setShellStyle(SWT.DIALOG_TRIM | SWT.RESIZE | SWT.MAX | SWT.APPLICATION_MODAL);
        this.phoneBook = phoneBook;
    }
    
    protected Control createContents(Composite parent) {
        Control contents = super.createContents(parent);
        parent.getShell().setText("Phone Book Editor");
        setTitle("Phone Book Editor");
        setMessage("Use this Phone Book Editor to view and manage your phone book entries");
        return contents;
    }
    
    protected Control createDialogArea(Composite parent) {
        Composite overallComposite = (Composite)super.createDialogArea(parent);
       
        Composite composite = new Composite(overallComposite, SWT.NONE);
        composite.setLayoutData(new GridData(GridData.FILL_BOTH));
        composite.setFont(composite.getFont());
        FormLayout layout = new FormLayout();
        composite.setLayout(layout);
        layout.marginHeight = 0;
        layout.marginWidth = 0;

        phoneBookComposite = createPhoneBookComposite(composite);
        
        FormData phoneBookCompositeFormData = new FormData();
        phoneBookCompositeFormData.top = new FormAttachment(0, 5);
        phoneBookCompositeFormData.left = new FormAttachment(0, 5);
        phoneBookCompositeFormData.right = new FormAttachment(100, -5);
        phoneBookCompositeFormData.bottom = new FormAttachment(100, -5);
        phoneBookComposite.setLayoutData(phoneBookCompositeFormData);
        
        updatePhoneBookEntriesTable();
        
        return overallComposite;
    }
    
    private Composite createPhoneBookComposite(Composite parent) {
        Composite composite = new Composite(parent, SWT.NULL);                
        composite.setFont(parent.getFont());
        FormLayout layout = new FormLayout();
        composite.setLayout(layout);
        layout.marginHeight = 0;
        layout.marginWidth = 0;
        
        phoneBookEntriesTable = new Table(composite, SWT.BORDER | SWT.FULL_SELECTION | SWT.MULTI);
        TableColumn tc1 = new TableColumn(phoneBookEntriesTable, SWT.CENTER);
        TableColumn tc2 = new TableColumn(phoneBookEntriesTable, SWT.CENTER);
        tc1.setText("Name");
        tc2.setText("Number");
        tc1.setWidth(150);
        tc1.setAlignment(SWT.LEFT);
        tc2.setWidth(100);
        tc2.setAlignment(SWT.LEFT);
        phoneBookEntriesTable.setHeaderVisible(true);
        updatePhoneBookEntriesTable();       
        phoneBookEntriesTable.addSelectionListener(new SelectionAdapter() {
            @Override
            public void widgetSelected(SelectionEvent event) {
                handlePhoneBookEntriesTableSelection();
            }
        });
        phoneBookEntriesTable.addMouseListener(new MouseAdapter() {            
            @Override
            public void mouseDoubleClick(MouseEvent e) {
                handleButtonPressed("Edit");
            }
        });
        phoneBookEntriesTable.setToolTipText("Phone Book Entries");

        
        // buttons
        newEntryButton = new Button(composite, SWT.PUSH);
        newEntryButton.setText("New...");
        newEntryButton.addSelectionListener(new SelectionAdapter() {
            @Override
            public void widgetSelected(SelectionEvent event) {
                handleButtonPressed("New");
            }
        });
        newEntryButton.setFont(parent.getFont());
        newEntryButton.setToolTipText("Create a new phone book entry");
      
        editEntryButton = new Button(composite, SWT.PUSH);
        editEntryButton.setText("Edit...");
        editEntryButton.addSelectionListener(new SelectionAdapter() {
            @Override
            public void widgetSelected(SelectionEvent event) {
                handleButtonPressed("Edit");
            }
        });
        editEntryButton.setFont(parent.getFont());
        editEntryButton.setToolTipText("Edit the selected phone book entry");
        
        removeEntryButton = new Button(composite, SWT.PUSH);
        removeEntryButton.setText("Remove");
        removeEntryButton.addSelectionListener(new SelectionAdapter() {
            @Override
            public void widgetSelected(SelectionEvent event) {
                handleButtonPressed("Remove");
            }
        });
        removeEntryButton.setFont(parent.getFont());
        removeEntryButton.setToolTipText("Remove the selected phone book entry from the phone book");
        
        // Layout the components in the composite     
        FormData newButtonFormData = new FormData();
        newButtonFormData.width = 50;
        newButtonFormData.top = new FormAttachment(0, 5);
        newButtonFormData.right = new FormAttachment(100, -5);
        newEntryButton.setLayoutData(newButtonFormData);
        
        FormData editButtonFormData = new FormData();
        editButtonFormData.width = 50;
        editButtonFormData.top = new FormAttachment(newEntryButton, 5);
        editButtonFormData.right = new FormAttachment(100, -5);
        editEntryButton.setLayoutData(editButtonFormData);
        
        FormData removeButtonFormData = new FormData();
        removeButtonFormData.width = 50;
        removeButtonFormData.top = new FormAttachment(editEntryButton, 5);
        removeButtonFormData.right = new FormAttachment(100, -5);
        removeEntryButton.setLayoutData(removeButtonFormData);
        
        FormData tableFormData = new FormData();
        tableFormData.top = new FormAttachment(0, 5);
        tableFormData.left = new FormAttachment(0, 5);
        tableFormData.right = new FormAttachment(newEntryButton, -10);
        tableFormData.bottom = new FormAttachment(100, -5);
        tableFormData.height = 100;
        phoneBookEntriesTable.setLayoutData(tableFormData);
        
        newEntryButton.setEnabled(true);
        editEntryButton.setEnabled(false);
        removeEntryButton.setEnabled(false);

        return composite;
    }

    void handleButtonPressed(String type) {
        PhoneBookEntryEditorDialog phoneBookEntryEditorDialog = null;
        int dialogResult = Window.CANCEL;
        PhoneBookEntry newEntry = null;
        if ("Remove".equals(type)) {
            for (TableItem itemToRemove : phoneBookEntriesTable.getSelection()) {
                phoneBook.removeEntry(itemToRemove.getText(0), itemToRemove.getText(1));
            }
            updatePhoneBookEntriesTable();
            return;
        } else if ("New".equals(type)) {
            newEntry = new PhoneBookEntry("enter name", "0");
            phoneBookEntryEditorDialog = new PhoneBookEntryEditorDialog(getShell(), newEntry);
            dialogResult = phoneBookEntryEditorDialog.open();
        } else if ("Edit".equals(type)) {           
            phoneBookEntryEditorDialog = new PhoneBookEntryEditorDialog(getShell(), phoneBook.getEntries().get(phoneBookEntriesTable.getSelectionIndex()));
            dialogResult = phoneBookEntryEditorDialog.open();
        }
        if (dialogResult == Window.OK) {
            if (newEntry != null) {
                try {
                    phoneBook.addEntry(newEntry);
                } catch (RuntimeException e) {
                    MessageDialog.openError(getShell(), "Problem adding entry", e.getMessage());
                }
            }
            updatePhoneBookEntriesTable();
        }
    }
    
    private void updatePhoneBookEntriesTable() {
        phoneBookEntriesTable.removeAll();        
        if (phoneBook != null) {            
            for (PhoneBookEntry entry : phoneBook.getEntries()) {
                TableItem item = new TableItem(phoneBookEntriesTable, SWT.NONE);                
                item.setText(new String[] {entry.getName(), entry.getNumber()});
            }
        }
        handlePhoneBookEntriesTableSelection();
    }
    
    void handlePhoneBookEntriesTableSelection() {
        if (newEntryButton != null && editEntryButton != null && removeEntryButton != null) {
            if (phoneBookEntriesTable.getSelectionCount() == 0) {
                newEntryButton.setEnabled(true);
                editEntryButton.setEnabled(false);
                removeEntryButton.setEnabled(false);
            } else if (phoneBookEntriesTable.getSelectionCount() == 1) {
                newEntryButton.setEnabled(true);
                editEntryButton.setEnabled(true);
                removeEntryButton.setEnabled(true);            
            } else {
                newEntryButton.setEnabled(true);
                editEntryButton.setEnabled(false);
                removeEntryButton.setEnabled(true);
            }
        }
    }
     
    @Override
    protected void okPressed() {
        setErrorMessage(null);
        setMessage(null);
        super.okPressed();
    }
}
