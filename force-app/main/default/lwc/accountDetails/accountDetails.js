import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

// Import Account fields
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_INDUSTRY from '@salesforce/schema/Account.Industry';
import ACCOUNT_PHONE from '@salesforce/schema/Account.Phone';
import ACCOUNT_WEBSITE from '@salesforce/schema/Account.Website';
import ACCOUNT_CREATED_DATE from '@salesforce/schema/Account.CreatedDate';

// Import Apex methods (commented out as they would need to exist in a real org)
// import calculateAccountScore from '@salesforce/apex/AccountService.calculateAccountScore';

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME,
    ACCOUNT_INDUSTRY, 
    ACCOUNT_PHONE,
    ACCOUNT_WEBSITE,
    ACCOUNT_CREATED_DATE
];

export default class AccountDetails extends NavigationMixin(LightningElement) {
    @api recordId; // This will be populated automatically on record pages
    @track account;
    @track error;
    @track isLoading = false;
    @track isCalculating = false;
    @track calculatedScore = 0;

    // Contact columns for the data table
    contactColumns = [
        { 
            label: 'Name', 
            fieldName: 'Name', 
            type: 'text',
            cellAttributes: { 
                iconName: 'standard:contact',
                iconPosition: 'left'
            }
        },
        { 
            label: 'Email', 
            fieldName: 'Email', 
            type: 'email'
        },
        { 
            label: 'Phone', 
            fieldName: 'Phone', 
            type: 'phone'
        },
        { 
            label: 'Title', 
            fieldName: 'Title', 
            type: 'text'
        }
    ];

    // Wire the account record
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount(result) {
        if (result.data) {
            this.account = {
                Id: result.data.id,
                Name: getFieldValue(result.data, ACCOUNT_NAME),
                Industry: getFieldValue(result.data, ACCOUNT_INDUSTRY),
                Phone: getFieldValue(result.data, ACCOUNT_PHONE),
                Website: getFieldValue(result.data, ACCOUNT_WEBSITE),
                CreatedDate: getFieldValue(result.data, ACCOUNT_CREATED_DATE),
                // Mock contacts data since we can't easily wire related records
                Contacts: this.generateMockContacts()
            };
            this.calculateInitialScore();
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Unknown error occurred';
            this.account = null;
        }
    }

    // Generate mock contacts for demonstration
    generateMockContacts() {
        return [
            {
                Id: 'contact1',
                Name: 'John Smith',
                Email: 'john.smith@example.com',
                Phone: '555-0101',
                Title: 'CEO'
            },
            {
                Id: 'contact2', 
                Name: 'Jane Doe',
                Email: 'jane.doe@example.com',
                Phone: '555-0102',
                Title: 'CTO'
            },
            {
                Id: 'contact3',
                Name: 'Bob Johnson',
                Email: 'bob.johnson@example.com', 
                Phone: '555-0103',
                Title: 'Sales Manager'
            }
        ];
    }

    // Calculate initial score when account loads
    calculateInitialScore() {
        if (this.account) {
            this.calculatedScore = this.calculateScoreLocally(this.account);
        }
    }

    // Local score calculation (mimics AccountService.calculateAccountScore)
    calculateScoreLocally(account) {
        let score = 0;
        
        // Score based on name length
        if (account.Name) {
            score += account.Name.length > 10 ? 25 : 15;
        }
        
        // Score based on industry
        if (account.Industry) {
            score += 20;
        }
        
        // Score based on phone
        if (account.Phone) {
            score += 15;
        }
        
        // Score based on website
        if (account.Website) {
            score += 20;
        }
        
        // Bonus for complete profile
        if (account.Name && account.Industry && account.Phone && account.Website) {
            score += 20;
        }
        
        return Math.min(score, 100);
    }

    // Computed properties
    get hasContacts() {
        return this.account?.Contacts && this.account.Contacts.length > 0;
    }

    get contactCount() {
        return this.account?.Contacts ? this.account.Contacts.length : 0;
    }

    get accountScoreLabel() {
        return `${this.calculatedScore}/100`;
    }

    get accountScoreClass() {
        if (this.calculatedScore >= 80) {
            return 'slds-theme_success';
        } else if (this.calculatedScore >= 60) {
            return 'slds-theme_warning';
        } else {
            return 'slds-theme_error';
        }
    }

    // Calculate score button handler
    calculateScore() {
        this.isCalculating = true;
        
        // Simulate API call delay
        setTimeout(() => {
            if (this.account) {
                const newScore = this.calculateScoreLocally(this.account);
                this.calculatedScore = newScore;
                
                this.showToast(
                    'Success', 
                    `Account score calculated: ${newScore}/100`, 
                    'success'
                );
            }
            this.isCalculating = false;
        }, 1000);

        // In a real implementation, you would call the Apex method:
        /*
        calculateAccountScore({ account: this.account })
            .then(result => {
                this.calculatedScore = result;
                this.showToast('Success', `Account score calculated: ${result}/100`, 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed to calculate score: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isCalculating = false;
            });
        */
    }

    // View full record
    viewFullRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
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