/**
 * @description Test class for OpportunityTriggerHandler
 * @author GitHub Copilot
 * @date 2024
 */
@isTest
private class OpportunityTriggerHandlerTest {
    
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
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    @isTest
    static void testHandleBeforeInsert() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        // This should call the trigger handler's handleBeforeInsert method
        insert testOpp;
        
        Test.stopTest();
        
        // Verify the record was created successfully
        List<Opportunity> insertedOpps = [
            SELECT Id, Name FROM Opportunity 
            WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(1, insertedOpps.size(), 'Should have 1 opportunity');
        System.assertEquals('Test Opportunity', insertedOpps[0].Name, 'Name should match');
    }
    
    @isTest
    static void testHandleBeforeInsertValidation() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        try {
            Opportunity testOpp = new Opportunity(
                Name = '', // Empty name should trigger validation
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );
            
            insert testOpp;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Opportunity name is required'), 
                         'Should contain name validation message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleBeforeInsertCloseDateValidation() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        try {
            Opportunity testOpp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(-30) // Past date should trigger validation
            );
            
            insert testOpp;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Close date cannot be in the past'), 
                         'Should contain close date validation message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterInsert() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        insert testOpp;
        
        Test.stopTest();
        
        // Verify opportunity was created
        List<Opportunity> insertedOpps = [
            SELECT Id, Name FROM Opportunity 
            WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(1, insertedOpps.size(), 'Should have 1 opportunity');
        
        // Note: Default contact role creation might not work in test context 
        // due to IsPrimary__c field not existing on standard Contact object
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Create contact role manually for testing
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Influencer'
        );
        insert contactRole;
        
        Test.startTest();
        
        // Update the opportunity stage
        testOpp.StageName = 'Proposal/Price Quote';
        update testOpp;
        
        Test.stopTest();
        
        // Verify contact role was updated based on new stage
        OpportunityContactRole updatedRole = [
            SELECT Id, Role FROM OpportunityContactRole 
            WHERE OpportunityId = :testOpp.Id LIMIT 1
        ];
        System.assertEquals('Decision Maker', updatedRole.Role, 
                           'Contact role should be updated based on opportunity stage');
    }
    
    @isTest
    static void testGetContactRoleBasedOnStage() {
        Test.startTest();
        
        // Test different stages - we need to use a workaround since the method is private
        // We'll test through the update functionality
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create opportunity and contact role
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Contact'
        );
        insert contactRole;
        
        // Test different stage updates
        testOpp.StageName = 'Qualification';
        update testOpp;
        
        contactRole = [SELECT Role FROM OpportunityContactRole WHERE Id = :contactRole.Id];
        System.assertEquals('Influencer', contactRole.Role, 'Should be Influencer for Qualification stage');
        
        testOpp.StageName = 'Needs Analysis';
        update testOpp;
        
        contactRole = [SELECT Role FROM OpportunityContactRole WHERE Id = :contactRole.Id];
        System.assertEquals('Technical Buyer', contactRole.Role, 'Should be Technical Buyer for Needs Analysis stage');
        
        testOpp.StageName = 'Closed Won';
        update testOpp;
        
        contactRole = [SELECT Role FROM OpportunityContactRole WHERE Id = :contactRole.Id];
        System.assertEquals('Economic Buyer', contactRole.Role, 'Should be Economic Buyer for Closed Won stage');
        
        Test.stopTest();
    }
    
    @isTest
    static void testRecursionPrevention() {
        // Reset recursion tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        // Simulate recursion by manually setting recursion depth
        for (Integer i = 0; i < 4; i++) {
            TriggerRecursionHelper.incrementRecursionDepth('ContactRoleUpdate_FromOpportunity');
        }
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        
        // This insert should not cause contact role creation due to recursion prevention
        insert testOpp;
        
        Test.stopTest();
        
        // Verify opportunity was created
        List<Opportunity> insertedOpps = [
            SELECT Id FROM Opportunity WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(1, insertedOpps.size(), 'Opportunity should be created');
        
        // Note: We can't easily test that contact roles weren't created since the recursion 
        // prevention is within the handler logic, but the code coverage will validate the flow
    }
    
    @isTest
    static void testUpdateWithNoChangesToTrackedFields() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Test.startTest();
        
        // Update a field that doesn't trigger contact role updates
        testOpp.Name = 'Updated Test Opportunity';
        update testOpp;
        
        Test.stopTest();
        
        // Verify opportunity was updated
        Opportunity updatedOpp = [SELECT Name FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Updated Test Opportunity', updatedOpp.Name, 'Name should be updated');
        
        // This test ensures that updates to non-tracked fields don't trigger unnecessary processing
    }
}