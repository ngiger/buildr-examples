package phonebookexample.dialogs;

import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.dialogs.TitleAreaDialog;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import phonebookexample.data.PhoneBookEntry;


public class PhoneBookEntryEditorDialog extends TitleAreaDialog {
    PhoneBookEntry phoneBookEntry;
    
    Composite phoneBookEntryComposite;
    Text nameText;
    Text numberText;
    
    private Listener simpleModifyListener = new Listener() {
        public void handleEvent(Event e) {
            handleEntryChanged();
        }
    };
    
    
    public PhoneBookEntryEditorDialog(Shell parent, PhoneBookEntry phoneBookEntry) {
        super(parent);
        setShellStyle(SWT.DIALOG_TRIM | SWT.RESIZE | SWT.MAX | SWT.APPLICATION_MODAL);
        this.phoneBookEntry = phoneBookEntry;
    }
    
    protected Control createContents(Composite parent) {
        Control contents = super.createContents(parent);
        parent.getShell().setText("Phone Book Entry Editor");
        setTitle("Phone Book Entry Editor");
        setMessage("Use this Phone Book Entry Editor to create and edit a phone book entry");
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

        phoneBookEntryComposite = createPhoneBookEntryComposite(composite);
        
        FormData phoneBookCompositeFormData = new FormData();
        phoneBookCompositeFormData.top = new FormAttachment(0, 5);
        phoneBookCompositeFormData.left = new FormAttachment(0, 5);
        phoneBookCompositeFormData.right = new FormAttachment(100, -5);
        phoneBookCompositeFormData.bottom = new FormAttachment(100, -5);
        phoneBookEntryComposite.setLayoutData(phoneBookCompositeFormData);
        
        updateView();
        nameText.addListener(SWT.Modify, simpleModifyListener); 
        numberText.addListener(SWT.Modify, simpleModifyListener); 
        
        return overallComposite;
    }
    
    private Composite createPhoneBookEntryComposite(Composite parent) {
        Composite composite = new Composite(parent, SWT.NULL);                
        composite.setFont(parent.getFont());
        FormLayout layout = new FormLayout();
        composite.setLayout(layout);
        layout.marginHeight = 0;
        layout.marginWidth = 0;

        Label nameLabel = new Label(composite, SWT.NONE);
        nameLabel.setText("Name:");
        nameLabel.setFont(parent.getFont());

        Label numberLabel = new Label(composite, SWT.NONE);
        numberLabel.setText("Number:");
        numberLabel.setFont(parent.getFont());

        nameText = new Text(composite, SWT.BORDER);
        nameText.setFont(parent.getFont());

        numberText = new Text(composite, SWT.BORDER);
        numberText.setFont(parent.getFont());
        
        // Layout the components in the composite
        FormData nameLabelFormData = new FormData();
        nameLabelFormData.top = new FormAttachment(0, 8);
        nameLabelFormData.left = new FormAttachment(0, 5);
        nameLabelFormData.width = 70;
        nameLabel.setLayoutData(nameLabelFormData);

        FormData numberLabelFormData = new FormData();
        numberLabelFormData.top = new FormAttachment(nameLabel, 10);
        numberLabelFormData.left = new FormAttachment(0, 5);
        numberLabelFormData.width = 70;
        numberLabel.setLayoutData(numberLabelFormData);
         
        FormData nameTextFormData = new FormData();
        nameTextFormData.top = new FormAttachment(nameLabel, 0, SWT.TOP);
        nameTextFormData.left = new FormAttachment(nameLabel, 20);
        nameTextFormData.right = new FormAttachment(100, -5);
        nameText.setLayoutData(nameTextFormData);
        
        FormData numberTextFormData = new FormData();
        numberTextFormData.top = new FormAttachment(numberLabel, 0, SWT.TOP);
        numberTextFormData.left = new FormAttachment(nameText, 0, SWT.LEFT);
        numberTextFormData.right = new FormAttachment(100, -5);
        numberText.setLayoutData(numberTextFormData);
        
        return composite;
    }

    void handleEntryChanged() {       
        try {
            phoneBookEntry.setName(nameText.getText());
            phoneBookEntry.setNumber(numberText.getText());
            setErrorMessage(null);
            setMessage("Use this Phone Book Entry Editor to create and edit a phone book entry");
            getButton(IDialogConstants.OK_ID).setEnabled(true);
        } catch (Exception e) {
            setErrorMessage("Problem with entry: " + e.getMessage());
            setMessage(null);
            getButton(IDialogConstants.OK_ID).setEnabled(false);
        }
    }
     
    @Override
    protected void okPressed() {
        handleEntryChanged();
        if (!getButton(IDialogConstants.OK_ID).isEnabled()) {
            return;
        }
        super.okPressed();
    }
    
    public PhoneBookEntry getPhoneBookEntry() {
        return phoneBookEntry;
    }
       
    private void updateView() {
        if (phoneBookEntry != null) {
            nameText.setText(phoneBookEntry.getName());
            numberText.setText(phoneBookEntry.getNumber());
        }
    }  
}
