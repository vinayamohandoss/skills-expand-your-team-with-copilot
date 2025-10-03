/**
 * @description Test class for TriggerRecursionHelper
 * @author GitHub Copilot
 * @date 2024
 */
@isTest
private class TriggerRecursionHelperTest {
    
    @isTest
    static void testHasAlreadyRun() {
        // Reset execution tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        // Initially should return false
        System.assertEquals(false, TriggerRecursionHelper.hasAlreadyRun('TestTrigger'), 
                           'Should return false for trigger that has not run');
        
        // Mark as run
        TriggerRecursionHelper.setHasRun('TestTrigger');
        
        // Now should return true
        System.assertEquals(true, TriggerRecursionHelper.hasAlreadyRun('TestTrigger'), 
                           'Should return true for trigger that has been marked as run');
        
        Test.stopTest();
    }
    
    @isTest
    static void testRecursionDepthTracking() {
        // Reset execution tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        String operationName = 'TestOperation';
        
        // Initially should not be exceeded
        System.assertEquals(false, TriggerRecursionHelper.isRecursionExceeded(operationName), 
                           'Should not be exceeded initially');
        
        // Current depth should be null/0
        System.assertEquals(null, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Initial depth should be null');
        
        // Increment depth multiple times
        TriggerRecursionHelper.incrementRecursionDepth(operationName);
        System.assertEquals(1, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should be 1 after first increment');
        
        TriggerRecursionHelper.incrementRecursionDepth(operationName);
        System.assertEquals(2, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should be 2 after second increment');
        
        TriggerRecursionHelper.incrementRecursionDepth(operationName);
        System.assertEquals(3, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should be 3 after third increment');
        
        // Should now be exceeded (max is 3)
        System.assertEquals(true, TriggerRecursionHelper.isRecursionExceeded(operationName), 
                           'Should be exceeded after reaching max depth');
        
        // Decrement depth
        TriggerRecursionHelper.decrementRecursionDepth(operationName);
        System.assertEquals(2, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should be 2 after decrement');
        
        // Should no longer be exceeded
        System.assertEquals(false, TriggerRecursionHelper.isRecursionExceeded(operationName), 
                           'Should not be exceeded after decrementing below max');
        
        Test.stopTest();
    }
    
    @isTest
    static void testDecrementDepthBeyondZero() {
        // Reset execution tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        String operationName = 'TestOperation';
        
        // Try to decrement when depth is null/0
        TriggerRecursionHelper.decrementRecursionDepth(operationName);
        System.assertEquals(null, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should remain null when decrementing from null');
        
        // Increment then decrement to 0
        TriggerRecursionHelper.incrementRecursionDepth(operationName);
        TriggerRecursionHelper.decrementRecursionDepth(operationName);
        System.assertEquals(0, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should be 0 after increment then decrement');
        
        // Try to decrement below 0
        TriggerRecursionHelper.decrementRecursionDepth(operationName);
        System.assertEquals(0, TriggerRecursionHelper.getCurrentRecursionDepth(operationName), 
                           'Depth should not go below 0');
        
        Test.stopTest();
    }
    
    @isTest
    static void testMultipleOperations() {
        // Reset execution tracking
        TriggerRecursionHelper.resetExecutionTracking();
        
        Test.startTest();
        
        String operation1 = 'Operation1';
        String operation2 = 'Operation2';
        
        // Test that different operations track independently
        TriggerRecursionHelper.incrementRecursionDepth(operation1);
        TriggerRecursionHelper.incrementRecursionDepth(operation1);
        
        TriggerRecursionHelper.incrementRecursionDepth(operation2);
        
        System.assertEquals(2, TriggerRecursionHelper.getCurrentRecursionDepth(operation1), 
                           'Operation1 should have depth 2');
        System.assertEquals(1, TriggerRecursionHelper.getCurrentRecursionDepth(operation2), 
                           'Operation2 should have depth 1');
        
        System.assertEquals(false, TriggerRecursionHelper.isRecursionExceeded(operation1), 
                           'Operation1 should not be exceeded');
        System.assertEquals(false, TriggerRecursionHelper.isRecursionExceeded(operation2), 
                           'Operation2 should not be exceeded');
        
        Test.stopTest();
    }
    
    @isTest
    static void testResetExecutionTracking() {
        Test.startTest();
        
        // Set up some tracking
        TriggerRecursionHelper.setHasRun('TestTrigger');
        TriggerRecursionHelper.incrementRecursionDepth('TestOperation');
        
        // Verify it's set
        System.assertEquals(true, TriggerRecursionHelper.hasAlreadyRun('TestTrigger'), 
                           'Trigger should be marked as run');
        System.assertEquals(1, TriggerRecursionHelper.getCurrentRecursionDepth('TestOperation'), 
                           'Operation should have depth 1');
        
        // Reset
        TriggerRecursionHelper.resetExecutionTracking();
        
        // Verify it's reset
        System.assertEquals(false, TriggerRecursionHelper.hasAlreadyRun('TestTrigger'), 
                           'Trigger should not be marked as run after reset');
        System.assertEquals(null, TriggerRecursionHelper.getCurrentRecursionDepth('TestOperation'), 
                           'Operation should have null depth after reset');
        
        Test.stopTest();
    }
}