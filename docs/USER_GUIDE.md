# TeamSync — User Guide

TeamSync is an asynchronous standup tool for remote teams. Instead of stopping
work for a meeting, each person writes a short standup (yesterday, today,
blockers) whenever it suits their timezone, and everyone else sees it in
real time.

---

## 1. Getting started

### Create an account

1. Open the app and choose **Sign up**.
2. Enter your **first name**, **last name**, **email** and a **password**
   (at least 8 characters).
3. Pick your **timezone** so standup times and reminders make sense for you.
4. You are logged in immediately.

### Log in

1. Choose **Log in**.
2. Enter your email and password.
3. Tick **Remember me** to stay signed in on this device.

Sessions stay active using a short-lived access token that refreshes
automatically. **Log out** revokes the refresh token for that device.

---

## 2. Teams

Teams are the unit of everything in TeamSync: standups, members and schedules.

### Create a team

1. From the sidebar choose **Create team**.
2. Enter a **name**, the team **timezone**, the daily **standup time** and the
   **days** standups are due (e.g. Monday–Friday).
3. You become the team **owner**.

### Roles and permissions

| Role | Can do |
| --- | --- |
| **Owner** | Everything, including deleting the team and transferring ownership |
| **Admin** | Update team settings and invite/remove members |
| **Member** | View the team, write their own standups |

### Invite people

1. Open your team → **Members** → **Invite**.
2. Enter the person's email and choose a role (**member** or **admin**).
3. If they already have a TeamSync account they are added to the team
   immediately and receive a notification; otherwise ask them to sign up first
   with that email.

### Join a team

If a team has shared an **invite code**, open the team's join page and enter the
code. You are added as a **member**.

### Remove a member / change a role

Admins can remove members. Owners can promote or demote members, and transfer
ownership. A team always keeps at least one owner, and you cannot remove
yourself.

---

## 3. Daily standups

### Write today's standup

1. Open **Today** in the sidebar.
2. Fill in:
   - **Yesterday** — what you accomplished.
   - **Today** — what you're working on.
   - **Blockers** — anything slowing you down (optional).
   - **Notes** — anything else (optional).
3. Choose **Save draft** to come back later, or **Submit standup** to publish.

Once submitted, everyone in the team sees it in real time.

### Editing

- Drafts can be edited freely.
- Submitted standups remain editable for **7 days** so you can fix typos or add
  missing details.
- Admins can edit or delete any standup in the team.

### History

Open **History** to browse past standups. You can filter by:

- **Date** or a **date range**
- **Member**
- **Status** — draft, submitted, missed, vacation, holiday

Your standup is marked **missed** automatically if the day passes without a
submission.

---

## 4. Timezones

Every time you see is shown in **your** timezone. Team standup times are stored
in the team's timezone and converted for each member, so a 9:00 AM standup in
London is shown at the right local time in Jakarta or New York.

Change your timezone any time in **Settings → Profile**.

---

## 5. Notifications

TeamSync keeps you informed without pulling you out of flow:

- **Standup reminders** — before your team's standup time (1 hour, 30 minutes
  and 10 minutes before).
- **New standup submitted** — when a teammate posts.
- **Team invitations** and **role changes**.
- **Daily summary** — admins/owners receive a recap of the previous day.

Open **Notifications** to read them. Click a notification to mark it read, or
use **Mark all as read**.

---

## 6. Real-time collaboration

- Standups appear instantly for everyone on the team as they are submitted.
- A **connection indicator** shows when the live connection is active.
- **Presence** shows who is currently online in a team.

If the connection drops, TeamSync reconnects automatically and catches up on
missed updates.

---

## 7. Settings

| Section | What you can change |
| --- | --- |
| **Profile** | First/last name, timezone, avatar |
| **Account** | Sign out of a device |

---

## 8. Tips for great standups

- Keep it short: what changed, what's next, what's blocked.
- Write it when it's convenient for you — this is asynchronous by design.
- Use blockers to surface problems early; teammates can jump in before the
  next sync.

---

## 9. FAQ

**Do I have to submit at the scheduled time?**
No. The standup time only drives reminders and the "due today" indicator. You
can write your standup any time.

**What happens if I don't submit?**
Your standup is automatically marked **missed** for that day.

**Can I be on more than one team?**
Yes. Use the team switcher in the sidebar to move between teams.

**Who can see my standups?**
Only members of that team.

**I forgot my password.**
Password recovery is not yet available; ask a team owner to help or contact your
administrator.
