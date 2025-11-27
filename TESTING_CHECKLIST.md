# Chat Feature Testing Checklist

## ✅ Complete Testing Guide

### Test 1: User Search & ID Verification
**Steps:**
1. Open admin app
2. Navigate to Messages
3. Click "New Message" button
4. Search for a user by name or email
5. **Check console output:**
   ```
   DEBUG NewMessageDialog: User ID=XXX, Name=YYY, Email=ZZZ
   ```
6. Note the User ID

**Expected:** User ID should be a valid user identifier (not empty, not null)

---

### Test 2: Send Message from Admin
**Steps:**
1. Select a user from search results
2. **Check console:**
   ```
   DEBUG NewMessageDialog: Selected user - ID=XXX, Name=YYY
   DEBUG NewMessageDialog: Navigating to /chat/XXX
   ```
3. Type a message: "Test from admin"
4. Click Send
5. **Check console:**
   ```
   [ChatNotifier] sendMessage - recipientId: XXX
   [ChatNotifier] sendMessage - actualRecipientId: XXX
   [ChatNotifier] Sending POST to /chat/XXX
   [ChatNotifier] Message sent successfully
   ```

**Expected:** 
- Message appears in admin's chat screen
- All IDs in console match
- No errors in console

---

### Test 3: Verify in User App
**Steps:**
1. Open user app (osp_broker)
2. Login as the user you messaged
3. Navigate to Messages/Chat
4. **Check if message appears**

**Expected:**
- Message "Test from admin" should appear in user's inbox
- Sender should show as admin's name
- Timestamp should be recent

**If message doesn't appear:**
- Check user's actual ID in their app
- Compare with the ID admin sent to
- Check debug output for ID mismatch

---

### Test 4: Reply from User
**Steps:**
1. In user app, reply to admin's message
2. In admin app, check if reply appears
3. **Check console in admin app:**
   ```
   DEBUG inbox: New message received, refreshing inbox
   ```

**Expected:**
- Admin's inbox updates automatically
- Reply appears in conversation
- Real-time update works

---

### Test 5: Inbox Display
**Steps:**
1. In admin app, go back to Messages list
2. **Check console:**
   ```
   DEBUG fetchRecipients response: {...}
   DEBUG ChatRecipient.fromJson received: {...}
   ```
3. Verify user name displays correctly (not "Unknown User")

**Expected:**
- User's full name appears
- Last message shows
- Timestamp is correct

---

### Test 6: Real-time Updates
**Steps:**
1. Keep admin Messages list open
2. Have user send a new message
3. Watch admin's inbox

**Expected:**
- Inbox refreshes automatically
- New conversation appears at top
- No manual refresh needed

---

## 🔍 Debug Output to Share

If issues persist, share these console outputs:

### From Admin App:
```
1. User search output:
   DEBUG NewMessageDialog: User ID=?, Name=?, Email=?

2. Message send output:
   [ChatNotifier] sendMessage - recipientId: ?
   [ChatNotifier] Sending POST to /chat/?
   [ChatNotifier] Response data: ?

3. Inbox output:
   DEBUG fetchRecipients response: ?
   DEBUG ChatRecipient.fromJson received: ?
```

### From User App:
```
1. User's logged-in ID
2. Inbox API response
3. Whether message appears or not
```

---

## Common Issues & Solutions

### Issue 1: "Unknown User" in Inbox
**Cause:** API response structure doesn't match parser
**Solution:** Check debug output for actual structure, adjust `ChatRecipient.fromJson()`

### Issue 2: Message Doesn't Appear in User App
**Cause:** ID mismatch - admin using wrong user ID
**Solution:** 
- Compare IDs in debug output
- Verify `/user` endpoint returns correct user IDs
- May need to fetch user profile to get actual ID

### Issue 3: Inbox Doesn't Update
**Cause:** Socket not connected or listener not working
**Solution:**
- Check socket connection status
- Verify `socketBootstrapProvider` is initialized
- Check for socket errors in console

### Issue 4: Real-time Not Working
**Cause:** Socket events not being received
**Solution:**
- Verify both apps connected to same socket server
- Check socket registration with correct user IDs
- Verify backend broadcasts messages correctly

---

## Success Criteria

✅ **All tests pass when:**
1. User search shows correct names and IDs
2. Admin can send messages to any user
3. Messages appear in user's inbox immediately
4. User can reply and admin sees it
5. Inbox shows correct user names (no "Unknown User")
6. Real-time updates work in both directions
7. No errors in console
8. All IDs match throughout the flow

---

**Test Status:** Ready for Testing  
**Date:** October 12, 2025
