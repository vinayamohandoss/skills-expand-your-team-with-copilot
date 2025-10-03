# Salesforce Repository with Apex Classes and LWC

Exercise: Expand your team with GitHub Copilot coding agent

This repository contains a complete Salesforce DX project structure with Apex classes and Lightning Web Components (LWC) for account management functionality.

## Project Structure

```
force-app/main/default/
├── classes/                    # Apex Classes
│   ├── AccountController.*     # Controller class for account operations
│   ├── AccountControllerTest.* # Test class for AccountController
│   ├── AccountService.*        # Service class for business logic
│   ├── AccountServiceTest.*    # Test class for AccountService
│   ├── QuoteController.*       # Controller class for quote operations
│   ├── QuoteControllerTest.*   # Test class for QuoteController
│   ├── TriggerRecursionHelper.* # Utility class for trigger recursion prevention
│   ├── TriggerRecursionHelperTest.* # Test class for TriggerRecursionHelper
│   ├── OpportunityTriggerHandler.* # Handler class for Opportunity trigger
│   ├── OpportunityTriggerHandlerTest.* # Test class for OpportunityTriggerHandler
│   ├── OpportunityContactRoleTriggerHandler.* # Handler class for OpportunityContactRole trigger
│   └── OpportunityContactRoleTriggerHandlerTest.* # Test class for OpportunityContactRoleTriggerHandler
├── triggers/                   # Apex Triggers
│   ├── OpportunityTrigger.*    # Trigger for Opportunity object with recursion prevention
│   └── OpportunityContactRoleTrigger.* # Trigger for OpportunityContactRole object with recursion prevention
├── lwc/                       # Lightning Web Components
│   ├── accountList/           # Account list management component
│   │   ├── accountList.html   # Component template
│   │   ├── accountList.js     # Component JavaScript controller
│   │   └── accountList.js-meta.xml # Component metadata
│   ├── accountDetails/        # Account details component
│   │   ├── accountDetails.html # Component template
│   │   ├── accountDetails.js   # Component JavaScript controller
│   │   └── accountDetails.js-meta.xml # Component metadata
│   └── quoteApproval/         # Quote approval process component
│       ├── quoteApproval.html  # Component template
│       ├── quoteApproval.js    # Component JavaScript controller
│       └── quoteApproval.js-meta.xml # Component metadata
├── objects/                   # Custom Objects (empty, ready for expansion)
├── tabs/                      # Custom Tabs (empty, ready for expansion)
└── applications/              # Custom Applications (empty, ready for expansion)
```

## Features

### Apex Classes

#### AccountController
- **Purpose**: Provides @AuraEnabled methods for Lightning components
- **Key Methods**:
  - `getAccountsWithContacts()` - Retrieves accounts with related contacts
  - `createAccount()` - Creates new account records
  - `updateAccount()` - Updates existing account records
- **Features**:
  - Error handling with AuraHandledException
  - Input validation
  - Configurable record limits

#### AccountService
- **Purpose**: Contains business logic and complex operations
- **Key Methods**:
  - `processAccounts()` - Validates and processes account data
  - `calculateAccountScore()` - Calculates account scoring metrics
  - `updateAccountScores()` - Bulk update of account scores
- **Features**:
  - Industry validation
  - Account scoring algorithm
  - Bulk processing capabilities

#### QuoteController
- **Purpose**: Provides @AuraEnabled methods for Quote approval process
- **Key Methods**:
  - `getQuoteWithShipToContact()` - Retrieves quote with ship-to contact details
  - `validateQuoteForApproval()` - Validates quote for approval submission
  - `submitQuoteForApproval()` - Submits quote for approval process
- **Features**:
  - Ship-to contact validation
  - Quote approval workflow
  - Error handling with detailed messages

#### TriggerRecursionHelper
- **Purpose**: Utility class to prevent trigger recursion and infinite loops
- **Key Methods**:
  - `hasAlreadyRun()` - Tracks trigger execution in current transaction
  - `isRecursionExceeded()` - Monitors recursion depth limits
  - `incrementRecursionDepth()` / `decrementRecursionDepth()` - Manages operation depth
- **Features**:
  - Operation-specific recursion tracking
  - Configurable recursion depth limits
  - Debug logging for recursion prevention
  - Thread-safe execution tracking

### Apex Triggers

#### OpportunityTrigger
- **Purpose**: Handles all Opportunity trigger events with recursion prevention
- **Events**: Before/After Insert, Before/After Update
- **Features**:
  - Comprehensive validation (name, close date)
  - Default contact role creation
  - Stage-based contact role updates
  - Recursion prevention using TriggerRecursionHelper

#### OpportunityContactRoleTrigger
- **Purpose**: Handles all OpportunityContactRole trigger events with recursion prevention
- **Events**: Before/After Insert, Before/After Update
- **Features**:
  - Contact role validation
  - Opportunity description updates
  - Change detection for optimized processing
  - Recursion prevention using TriggerRecursionHelper

### Lightning Web Components

#### Account List (accountList)
- **Purpose**: Displays and manages a list of accounts
- **Features**:
  - Data table with sortable columns
  - Search functionality
  - Configurable record limits
  - Account creation modal
  - Real-time data refresh
  - Row actions (view/edit)
  - Toast notifications

#### Account Details (accountDetails)
- **Purpose**: Shows detailed account information
- **Features**:
  - Account field display with proper formatting
  - Account score calculation and visualization
  - Related contacts display
  - Navigation integration
  - **Real-time score updates**
  - Responsive design

#### Quote Approval (quoteApproval)
- **Purpose**: Handles quote approval process with validation
- **Features**:
  - Ship-to contact validation
  - Interactive approval interface
  - Error messaging for validation failures
  - Submit button state management
  - Real-time validation feedback
  - Integration with quote workflow
  - Toast notifications for user feedback

## Trigger Recursion Prevention

This repository includes a comprehensive solution for preventing trigger recursion issues, specifically addressing the "maximum trigger depth exceeded" errors that can occur with interconnected triggers.

### Problem Addressed
- **Issue**: Circular trigger execution between Opportunity, OpportunityContactRole, and Contract triggers
- **Error**: `System.DmlException: maximum trigger depth exceeded`
- **Root Cause**: Triggers updating related records that trigger other triggers in an infinite loop

### Solution Implemented
- **TriggerRecursionHelper**: Centralized utility for tracking and preventing recursion
- **Recursion Depth Monitoring**: Configurable limits (default: 3 levels) per operation type
- **Operation Isolation**: Different trigger operations have separate recursion tracking
- **Try/Finally Pattern**: Ensures proper cleanup of recursion counters
- **Comprehensive Logging**: Debug logs help identify and troubleshoot recursion scenarios

### Files Included
- `error.log`: Original error log showing the recursion issue
- `TRIGGER_RECURSION_SOLUTION.md`: Detailed technical documentation
- Trigger files with recursion prevention built-in
- Comprehensive test coverage for all recursion scenarios

For detailed technical information, see [TRIGGER_RECURSION_SOLUTION.md](TRIGGER_RECURSION_SOLUTION.md).

## Deployment

### Prerequisites
- Salesforce CLI (sfdx) installed
- Connected to a Salesforce org

### Deploy to Salesforce
```bash
# Deploy all metadata
sfdx force:source:deploy -p force-app/main/default

# Or deploy specific components
sfdx force:source:deploy -m "ApexClass:AccountController,LightningComponentBundle:accountList"

# Run tests
sfdx force:apex:test:run -c -r human
```

### Using Package.xml
```bash
# Deploy using manifest
sfdx force:mdapi:deploy -d manifest/
```

## Testing

The project includes comprehensive test classes:
- **AccountControllerTest**: Tests all controller methods with various scenarios
- **AccountServiceTest**: Tests business logic and edge cases
- **QuoteControllerTest**: Tests quote approval validation and submission processes
- **TriggerRecursionHelperTest**: Tests recursion tracking and prevention mechanisms
- **OpportunityTriggerHandlerTest**: Tests opportunity trigger business logic and validation
- **OpportunityContactRoleTriggerHandlerTest**: Tests contact role trigger business logic and validation

All test classes achieve high code coverage and include:
- Positive test scenarios
- Negative test scenarios
- Edge case handling
- Data setup methods
- Assertion validations
- Recursion prevention testing
- Trigger execution flow validation

## Configuration Files

- **sfdx-project.json**: Salesforce DX project configuration
- **.gitignore**: Git ignore rules for Salesforce projects
- **.sfdxignore**: SFDX deployment ignore rules
- **manifest/package.xml**: Deployment package definition

## Usage

1. Deploy the components to your Salesforce org
2. Add the Lightning components to your Lightning pages:
   - Add `accountList` component to app pages or home pages
   - Add `accountDetails` component to Account record pages
   - Add `quoteApproval` component to Quote record pages or as a Quick Action/Record Action
3. Configure component visibility and permissions as needed

## Development Notes

- All Apex classes follow Salesforce best practices
- Lightning Web Components use modern LWC patterns
- Components are designed for reusability and maintainability
- Error handling is implemented throughout
- Code is documented with comprehensive comments

## Future Enhancements

The project structure allows for easy expansion:
- Add custom objects in the `objects/` directory
- Create custom tabs in the `tabs/` directory
- Build custom applications in the `applications/` directory
- Extend Apex classes with additional business logic
- Create more Lightning Web Components for enhanced functionality
