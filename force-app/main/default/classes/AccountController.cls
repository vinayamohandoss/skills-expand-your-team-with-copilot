/**
 * @description Controller class for managing Account operations
 * @author GitHub Copilot
 * @date 2024
 */
public with sharing class AccountController {
    
    /**
     * @description Retrieves a list of accounts with their related contacts
     * @param limitSize Number of records to return
     * @return List of Account records with contacts
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsWithContacts(Integer limitSize) {
        try {
            limitSize = limitSize != null ? limitSize : 10;
            
            return [
                SELECT Id, Name, Industry, Phone, Website,
                       (SELECT Id, FirstName, LastName, Email, Phone FROM Contacts LIMIT 5)
                FROM Account 
                WHERE Name != null 
                ORDER BY CreatedDate DESC 
                LIMIT :limitSize
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new account record
     * @param accountName Name of the account to create
     * @param industry Industry of the account
     * @return Id of the created account
     */
    @AuraEnabled
    public static Id createAccount(String accountName, String industry) {
        try {
            if (String.isBlank(accountName)) {
                throw new IllegalArgumentException('Account name cannot be empty');
            }
            
            Account newAccount = new Account(
                Name = accountName,
                Industry = industry
            );
            
            insert newAccount;
            return newAccount.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating account: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates an existing account record
     * @param accountId Id of the account to update
     * @param accountName New name for the account
     * @param industry New industry for the account
     * @return Boolean indicating success
     */
    @AuraEnabled
    public static Boolean updateAccount(Id accountId, String accountName, String industry) {
        try {
            if (accountId == null) {
                throw new IllegalArgumentException('Account ID cannot be null');
            }
            
            Account accountToUpdate = new Account(
                Id = accountId,
                Name = accountName,
                Industry = industry
            );
            
            update accountToUpdate;
            return true;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
    }
}