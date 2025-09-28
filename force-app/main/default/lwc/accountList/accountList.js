import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAccountsWithContacts from '@salesforce/apex/AccountController.getAccountsWithContacts';
import createAccount from '@salesforce/apex/AccountController.createAccount';

export default class AccountList extends LightningElement {
    @track accounts = [];
    @track filteredAccounts = [];
    @track error;
    @track isLoading = false;
    @track searchTerm = '';
    @track selectedLimit = 10;
    @track showCreateModal = false;
    @track newAccountName = '';
    @track newAccountIndustry = '';
    
    wiredAccountsResult;

    // Column definitions for the data table
    columns = [
        { 
            label: 'Account Name', 
            fieldName: 'Name', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Industry', 
            fieldName: 'Industry', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Phone', 
            fieldName: 'Phone', 
            type: 'phone',
            sortable: true
        },
        { 
            label: 'Website', 
            fieldName: 'Website', 
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: { fieldName: 'Website' },
                target: '_blank'
            }
        },
        { 
            label: 'Contacts Count', 
            fieldName: 'ContactsCount', 
            type: 'number',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    // Limit options for combobox
    limitOptions = [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '15', value: 15 },
        { label: '20', value: 20 },
        { label: '50', value: 50 }
    ];

    // Industry options for account creation
    industryOptions = [
        { label: 'Technology', value: 'Technology' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Manufacturing', value: 'Manufacturing' },
        { label: 'Education', value: 'Education' },
        { label: 'Retail', value: 'Retail' },
        { label: 'Consulting', value: 'Consulting' },
        { label: 'Other', value: 'Other' }
    ];

    // Wire method to get accounts
    @wire(getAccountsWithContacts, { limitSize: '$selectedLimit' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) {
            this.processAccountData(result.data);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Unknown error occurred';
            this.accounts = [];
            this.filteredAccounts = [];
        }
    }

    // Process account data to add calculated fields
    processAccountData(data) {
        this.accounts = data.map(account => ({
            ...account,
            ContactsCount: account.Contacts ? account.Contacts.length : 0
        }));
        this.filterAccounts();
    }

    // Filter accounts based on search term
    filterAccounts() {
        if (!this.searchTerm) {
            this.filteredAccounts = [...this.accounts];
        } else {
            const searchLower = this.searchTerm.toLowerCase();
            this.filteredAccounts = this.accounts.filter(account =>
                account.Name?.toLowerCase().includes(searchLower) ||
                account.Industry?.toLowerCase().includes(searchLower)
            );
        }
    }

    // Get computed property for checking if accounts exist
    get hasAccounts() {
        return this.filteredAccounts && this.filteredAccounts.length > 0;
    }

    // Handle search input change
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.filterAccounts();
    }

    // Handle limit selection change
    handleLimitChange(event) {
        this.selectedLimit = parseInt(event.detail.value);
    }

    // Refresh data
    refreshData() {
        this.isLoading = true;
        refreshApex(this.wiredAccountsResult)
            .then(() => {
                this.showToast('Success', 'Data refreshed successfully', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed to refresh data: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Handle row actions
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch (actionName) {
            case 'view':
                this.viewAccount(row.Id);
                break;
            case 'edit':
                this.editAccount(row.Id);
                break;
            default:
                break;
        }
    }

    // View account (placeholder - would navigate to account detail page)
    viewAccount(accountId) {
        this.showToast('Info', `Viewing account: ${accountId}`, 'info');
        // In a real implementation, this would use NavigationMixin to navigate to the account
    }

    // Edit account (placeholder - would open edit modal or navigate to edit page)
    editAccount(accountId) {
        this.showToast('Info', `Editing account: ${accountId}`, 'info');
        // In a real implementation, this would open an edit modal or navigate to edit page
    }

    // Modal management methods
    openCreateModal() {
        this.showCreateModal = true;
        this.resetCreateForm();
    }

    closeCreateModal() {
        this.showCreateModal = false;
        this.resetCreateForm();
    }

    resetCreateForm() {
        this.newAccountName = '';
        this.newAccountIndustry = '';
    }

    // Handle form input changes
    handleAccountNameChange(event) {
        this.newAccountName = event.target.value;
    }

    handleIndustryChange(event) {
        this.newAccountIndustry = event.detail.value;
    }

    // Create new account
    createAccount() {
        if (!this.newAccountName) {
            this.showToast('Error', 'Account name is required', 'error');
            return;
        }

        this.isLoading = true;
        
        createAccount({ 
            accountName: this.newAccountName, 
            industry: this.newAccountIndustry 
        })
        .then(result => {
            this.showToast('Success', 'Account created successfully', 'success');
            this.closeCreateModal();
            return refreshApex(this.wiredAccountsResult);
        })
        .catch(error => {
            this.showToast('Error', 'Failed to create account: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}