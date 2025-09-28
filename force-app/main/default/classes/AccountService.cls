/**
 * @description Service class for complex business logic operations
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class AccountService {
    
    /**
     * @description Processes account data and applies business rules
     * @param accounts List of accounts to process
     * @return Map of account Id to processing result
     */
    public static Map<Id, String> processAccounts(List<Account> accounts) {
        Map<Id, String> results = new Map<Id, String>();
        
        if (accounts == null || accounts.isEmpty()) {
            return results;
        }
        
        for (Account acc : accounts) {
            String result = validateAndProcessAccount(acc);
            results.put(acc.Id, result);
        }
        
        return results;
    }
    
    /**
     * @description Validates account data and applies business logic
     * @param account Account record to validate and process
     * @return String indicating the processing result
     */
    private static String validateAndProcessAccount(Account account) {
        List<String> validationErrors = new List<String>();
        
        // Validate account name
        if (String.isBlank(account.Name)) {
            validationErrors.add('Account name is required');
        } else if (account.Name.length() < 3) {
            validationErrors.add('Account name must be at least 3 characters');
        }
        
        // Validate industry
        if (String.isNotBlank(account.Industry)) {
            Set<String> validIndustries = new Set<String>{
                'Technology', 'Healthcare', 'Finance', 'Manufacturing', 
                'Education', 'Retail', 'Consulting', 'Other'
            };
            
            if (!validIndustries.contains(account.Industry)) {
                validationErrors.add('Invalid industry specified');
            }
        }
        
        // Return validation results
        if (!validationErrors.isEmpty()) {
            return 'Validation Failed: ' + String.join(validationErrors, '; ');
        }
        
        return 'Processing Successful';
    }
    
    /**
     * @description Calculates account score based on various factors
     * @param account Account to score
     * @return Decimal score between 0-100
     */
    public static Decimal calculateAccountScore(Account account) {
        Decimal score = 0;
        
        if (account == null) {
            return score;
        }
        
        // Score based on name length
        if (String.isNotBlank(account.Name)) {
            score += account.Name.length() > 10 ? 25 : 15;
        }
        
        // Score based on industry
        if (String.isNotBlank(account.Industry)) {
            score += 20;
        }
        
        // Score based on phone
        if (String.isNotBlank(account.Phone)) {
            score += 15;
        }
        
        // Score based on website
        if (String.isNotBlank(account.Website)) {
            score += 20;
        }
        
        // Bonus for complete profile
        if (String.isNotBlank(account.Name) && 
            String.isNotBlank(account.Industry) && 
            String.isNotBlank(account.Phone) && 
            String.isNotBlank(account.Website)) {
            score += 20;
        }
        
        return Math.min(score, 100);
    }
    
    /**
     * @description Bulk operation to update account scores
     * @param accountIds Set of account IDs to update scores for
     */
    public static void updateAccountScores(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        List<Account> accountsToUpdate = [
            SELECT Id, Name, Industry, Phone, Website
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : accountsToUpdate) {
            Decimal score = calculateAccountScore(acc);
            // In a real implementation, you might have a custom field to store the score
            acc.Description = 'Account Score: ' + score;
        }
        
        update accountsToUpdate;
    }
}