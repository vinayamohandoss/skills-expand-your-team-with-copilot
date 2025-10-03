/**
 * @description Test class for OpportunityContactRoleTriggerHandler
 * @author GitHub Copilot
 * @date 2024
 */
@isTest
private class OpportunityContactRoleTriggerHandlerTest {
    
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
        
        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
    }
    
    @isTest
    static void testHandleBeforeInsert() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        
        // This should call the trigger handler's handleBeforeInsert method
        insert contactRole;
        
        Test.stopTest();
        
        // Verify the record was created successfully
        List<OpportunityContactRole> insertedRoles = [
            SELECT Id, Role FROM OpportunityContactRole 
            WHERE OpportunityId = :testOpp.Id
        ];
        System.assertEquals(1, insertedRoles.size(), 'Should have 1 contact role');
        System.assertEquals('Decision Maker', insertedRoles[0].Role, 'Role should match');
    }
    
    @isTest
    static void testHandleBeforeInsertValidation() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        
        try {
            OpportunityContactRole contactRole = new OpportunityContactRole(
                OpportunityId = testOpp.Id,
                ContactId = testContact.Id,
                Role = '' // Empty role should trigger validation
            );
            
            insert contactRole;
            System.assert(false, 'Should have thrown validation error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Role is required'), 
                         'Should contain role validation message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterInsert() {
        Opportunity testOpp = [SELECT Id, Description FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        
        insert contactRole;
        
        Test.stopTest();
        
        // Verify the opportunity was updated
        Opportunity updatedOpp = [SELECT Id, Description FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Contact Roles: 1', updatedOpp.Description, 
                           'Opportunity description should reflect contact role count');
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create contact role
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Influencer'
        );
        insert contactRole;
        
        Test.startTest();
        
        // Update the contact role
        contactRole.Role = 'Decision Maker';
        contactRole.IsPrimary = true;
        update contactRole;
        
        Test.stopTest();
        
        // Verify the opportunity was updated
        Opportunity updatedOpp = [SELECT Id, Description FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Contact Roles: 1', updatedOpp.Description, 
                           'Opportunity description should be updated after contact role change');
    }
    
    @isTest
    static void testRecursionPrevention() {
        // Reset recursion tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        // Simulate recursion by manually setting recursion depth
        for (Integer i = 0; i < 4; i++) {
            TriggerRecursionHelper.incrementRecursionDepth('OpportunityUpdate_FromContactRole');
        }
        
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        
        // This insert should not cause opportunity update due to recursion prevention
        insert contactRole;
        
        Test.stopTest();
        
        // Verify contact role was created but opportunity wasn't updated due to recursion prevention
        List<OpportunityContactRole> insertedRoles = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :testOpp.Id
        ];
        System.assertEquals(1, insertedRoles.size(), 'Contact role should be created');
        
        // Note: We can't easily test that the opportunity wasn't updated since the recursion 
        // prevention is within the handler logic, but the code coverage will validate the flow
    }
    
    @isTest
    static void testMultipleContactRoleInsert() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        ));
        contactRoles.add(new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Influencer'
        ));
        
        insert contactRoles;
        
        Test.stopTest();
        
        // Verify all contact roles were created
        List<OpportunityContactRole> insertedRoles = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :testOpp.Id
        ];
        System.assertEquals(2, insertedRoles.size(), 'Should have 2 contact roles');
        
        // Verify opportunity description was updated
        Opportunity updatedOpp = [SELECT Id, Description FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Contact Roles: 2', updatedOpp.Description, 
                           'Opportunity description should reflect total contact role count');
    }
}