import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateQuoteForApproval from '@salesforce/apex/QuoteController.validateQuoteForApproval';
import submitQuoteForApproval from '@salesforce/apex/QuoteController.submitQuoteForApproval';

export default class QuoteApproval extends LightningElement {
    @api recordId; // Quote record ID passed from the page
    @track quote;
    @track validationErrors = [];
    @track isLoading = true;
    @track isSubmitting = false;

    // Wire method to validate quote on component load
    @wire(validateQuoteForApproval, { quoteId: '$recordId' })
    wiredValidation(result) {
        this.isLoading = false;
        if (result.data) {
            this.processValidationResult(result.data);
        } else if (result.error) {
            this.handleError('Error validating quote: ' + (result.error.body?.message || result.error.message));
        }
    }

    // Process validation results
    processValidationResult(data) {
        this.quote = data.quote;
        this.validationErrors = data.errors || [];
        
        if (this.validationErrors.length === 0) {
            this.showToast('Success', 'Quote validation passed. Ready for submission.', 'success');
        }
    }

    // Computed property to determine if submit button should be disabled
    get isSubmitDisabled() {
        return this.isLoading || this.isSubmitting || this.hasValidationErrors;
    }

    // Computed property to check if there are validation errors
    get hasValidationErrors() {
        return this.validationErrors && this.validationErrors.length > 0;
    }

    // Computed property to get error message display
    get errorMessage() {
        if (this.hasValidationErrors) {
            return this.validationErrors.join(' ');
        }
        return '';
    }

    // Computed property for submit button variant
    get submitButtonVariant() {
        return this.hasValidationErrors ? 'neutral' : 'brand';
    }

    // Handle submit for approval button click
    handleSubmitForApproval() {
        this.isSubmitting = true;
        
        submitQuoteForApproval({ quoteId: this.recordId })
            .then(() => {
                this.showToast(
                    'Success', 
                    'Quote has been submitted for approval successfully.', 
                    'success'
                );
                // Close the action screen/modal if running in action context
                this.closeAction();
            })
            .catch(error => {
                this.handleError('Failed to submit quote for approval: ' + (error.body?.message || error.message));
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    // Handle cancel button click
    handleCancel() {
        this.closeAction();
    }

    // Close the action screen
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Handle errors
    handleError(message) {
        this.showToast('Error', message, 'error');
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