/**
 * @description Test class for QuoteController
 * @author GitHub Copilot
 * @date 2024
 */
@isTest
private class QuoteControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '555-0123',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test opportunity (required for Quote)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
        
        // Create test quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Status = 'Draft'
        );
        insert testQuote;
    }
    
    @isTest
    static void testGetQuoteWithShipToContact_Success() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        Quote result = QuoteController.getQuoteWithShipToContact(testQuote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Quote should be returned');
        System.assertEquals(testQuote.Id, result.Id, 'Quote ID should match');
        System.assertEquals('Test Quote', result.Name, 'Quote name should match');
    }
    
    @isTest
    static void testGetQuoteWithShipToContact_NullId() {
        Test.startTest();
        try {
            QuoteController.getQuoteWithShipToContact(null);
            System.assert(false, 'Should throw exception for null ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Quote ID cannot be null'), 'Should contain proper error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateQuoteForApproval_WithoutShipToContact() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = QuoteController.validateQuoteForApproval(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.get('isValid'), 'Quote should not be valid without ship-to contact');
        List<String> errors = (List<String>)result.get('errors');
        System.assert(!errors.isEmpty(), 'Should have validation errors');
        System.assert(errors[0].contains('Ship To Contact'), 'Should contain ship-to contact error');
    }
    
    @isTest
    static void testValidateQuoteForApproval_WithShipToContact() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Update quote with ship-to contact
        testQuote.ShipToContactId = testContact.Id;
        update testQuote;
        
        Test.startTest();
        Map<String, Object> result = QuoteController.validateQuoteForApproval(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('isValid'), 'Quote should be valid with ship-to contact');
        List<String> errors = (List<String>)result.get('errors');
        System.assert(errors.isEmpty(), 'Should have no validation errors');
    }
    
    @isTest
    static void testSubmitQuoteForApproval_Success() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Update quote with ship-to contact
        testQuote.ShipToContactId = testContact.Id;
        update testQuote;
        
        Test.startTest();
        Boolean result = QuoteController.submitQuoteForApproval(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Submission should be successful');
        
        // Verify quote status was updated
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals('In Review', updatedQuote.Status, 'Quote status should be updated to In Review');
    }
    
    @isTest
    static void testSubmitQuoteForApproval_ValidationFailure() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            QuoteController.submitQuoteForApproval(testQuote.Id);
            System.assert(false, 'Should throw exception for validation failure');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Validation failed'), 'Should contain validation error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitQuoteForApproval_NullId() {
        Test.startTest();
        try {
            QuoteController.submitQuoteForApproval(null);
            System.assert(false, 'Should throw exception for null ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Quote ID cannot be null'), 'Should contain proper error message');
        }
        Test.stopTest();
    }
}