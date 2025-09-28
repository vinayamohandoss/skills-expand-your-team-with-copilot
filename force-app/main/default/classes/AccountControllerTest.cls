/**
 * @description Test class for AccountController
 * @author GitHub Copilot
 * @date 2024
 */
@isTest
private class AccountControllerTest {
    
    /**
     * @description Test data setup method
     */
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 1; i <= 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                Phone = '555-000-000' + i,
                Website = 'https://testaccount' + i + '.com'
            ));
        }
        
        insert testAccounts;
        
        // Create contacts for the first account
        Account firstAccount = testAccounts[0];
        List<Contact> testContacts = new List<Contact>();
        
        for (Integer i = 1; i <= 3; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'testcontact' + i + '@example.com',
                Phone = '555-111-000' + i,
                AccountId = firstAccount.Id
            ));
        }
        
        insert testContacts;
    }
    
    /**
     * @description Test getAccountsWithContacts method with valid data
     */
    @isTest
    static void testGetAccountsWithContactsSuccess() {
        Test.startTest();
        List<Account> result = AccountController.getAccountsWithContacts(3);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should return 3 accounts');
        
        // Check if the first account has contacts
        Boolean foundAccountWithContacts = false;
        for (Account acc : result) {
            if (!acc.Contacts.isEmpty()) {
                foundAccountWithContacts = true;
                System.assertEquals(3, acc.Contacts.size(), 'First account should have 3 contacts');
                break;
            }
        }
        System.assertEquals(true, foundAccountWithContacts, 'At least one account should have contacts');
    }
    
    /**
     * @description Test getAccountsWithContacts method with null limit
     */
    @isTest
    static void testGetAccountsWithContactsNullLimit() {
        Test.startTest();
        List<Account> result = AccountController.getAccountsWithContacts(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(5, result.size(), 'Should return all 5 accounts when limit is null');
    }
    
    /**
     * @description Test createAccount method with valid data
     */
    @isTest
    static void testCreateAccountSuccess() {
        String accountName = 'New Test Account';
        String industry = 'Healthcare';
        
        Test.startTest();
        Id accountId = AccountController.createAccount(accountName, industry);
        Test.stopTest();
        
        System.assertNotEquals(null, accountId, 'Account ID should not be null');
        
        Account createdAccount = [SELECT Name, Industry FROM Account WHERE Id = :accountId];
        System.assertEquals(accountName, createdAccount.Name, 'Account name should match');
        System.assertEquals(industry, createdAccount.Industry, 'Industry should match');
    }
    
    /**
     * @description Test createAccount method with blank name
     */
    @isTest
    static void testCreateAccountBlankName() {
        Test.startTest();
        try {
            AccountController.createAccount('', 'Technology');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account name cannot be empty'), 
                         'Error message should mention empty name');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test updateAccount method with valid data
     */
    @isTest
    static void testUpdateAccountSuccess() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String newName = 'Updated Account Name';
        String newIndustry = 'Finance';
        
        Test.startTest();
        Boolean result = AccountController.updateAccount(testAccount.Id, newName, newIndustry);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Update should be successful');
        
        Account updatedAccount = [SELECT Name, Industry FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(newName, updatedAccount.Name, 'Name should be updated');
        System.assertEquals(newIndustry, updatedAccount.Industry, 'Industry should be updated');
    }
    
    /**
     * @description Test updateAccount method with null ID
     */
    @isTest
    static void testUpdateAccountNullId() {
        Test.startTest();
        try {
            AccountController.updateAccount(null, 'Test Name', 'Technology');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account ID cannot be null'), 
                         'Error message should mention null ID');
        }
        Test.stopTest();
    }
}