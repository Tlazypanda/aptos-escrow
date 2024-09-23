Flow: 

- Imagine a freelancing application 
- When 2 parties agree to some terms, the create_escrow function will be called which will create an escrow. The paying entity funds are then locked into this escrow 
- After this the other party will submit some work if it's good then it will get approved. On approval the escrow will unlock and the receiving party will be paid
- Incase due to some reason the party is not able to produce good work or any work at all, the escrow can be canceled after a given time period (14 days by default) only
-  If the work is rejected, the escrow funds are released
