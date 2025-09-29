/**
 * @description Controller class for managing Quote operations
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class QuoteController {
    
    /**
     * @description Retrieves quote record with ship-to and bill-to contact details
     * @param quoteId Id of the quote record
     * @return Quote record with ship-to and bill-to contact information
     */
    @AuraEnabled(cacheable=true)
    public static Quote getQuoteWithShipToContact(Id quoteId) {
        try {
            if (quoteId == null) {
                throw new IllegalArgumentException('Quote ID cannot be null');
            }
            
            return [
                SELECT Id, Name, Status, ShipToContactId, ShipToContact.Name, 
                       ShipToContact.Email, ShipToContact.Phone, BillToContactId,
                       BillToContact.Name, BillToContact.Email, BillToContact.Phone, Account.Name
                FROM Quote 
                WHERE Id = :quoteId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving quote: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates quote for approval submission
     * @param quoteId Id of the quote to validate
     * @return Map containing validation results
     */
    @AuraEnabled
    public static Map<String, Object> validateQuoteForApproval(Id quoteId) {
        Map<String, Object> result = new Map<String, Object>();
        List<String> errors = new List<String>();
        
        try {
            if (quoteId == null) {
                errors.add('Quote ID is required');
                result.put('isValid', false);
                result.put('errors', errors);
                return result;
            }
            
            Quote quote = getQuoteWithShipToContact(quoteId);
            
            // Validate ship-to contact
            if (quote.ShipToContactId == null) {
                errors.add('Quote must have a Ship To Contact before submitting for approval.');
            }
            
            // Validate bill-to contact
            if (quote.BillToContactId == null) {
                errors.add('Quote must have a Bill To Contact before submitting for approval.');
            }
            
            // Add other validation rules as needed
            if (String.isBlank(quote.Name)) {
                errors.add('Quote name is required');
            }
            
            result.put('isValid', errors.isEmpty());
            result.put('errors', errors);
            result.put('quote', quote);
            
        } catch (Exception e) {
            errors.add('Error validating quote: ' + e.getMessage());
            result.put('isValid', false);
            result.put('errors', errors);
        }
        
        return result;
    }
    
    /**
     * @description Submits quote for approval
     * @param quoteId Id of the quote to submit
     * @return Boolean indicating success
     */
    @AuraEnabled
    public static Boolean submitQuoteForApproval(Id quoteId) {
        try {
            if (quoteId == null) {
                throw new IllegalArgumentException('Quote ID cannot be null');
            }
            
            // First validate the quote
            Map<String, Object> validation = validateQuoteForApproval(quoteId);
            if (!(Boolean)validation.get('isValid')) {
                List<String> errors = (List<String>)validation.get('errors');
                throw new AuraHandledException('Validation failed: ' + String.join(errors, '; '));
            }
            
            // Update quote status to submitted for approval
            Quote quoteToUpdate = new Quote(
                Id = quoteId,
                Status = 'In Review'
            );
            
            update quoteToUpdate;
            
            // In a real implementation, you might also:
            // - Create approval process records
            // - Send notifications
            // - Log the submission
            
            return true;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting quote for approval: ' + e.getMessage());
        }
    }
}