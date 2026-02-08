# CLAUDE.md

I want add following a function to backend web.
My backend is /Volumes/SSD-PSTU3A/work/dev/serifu/sys/backend.
And also the function use only admin user.

## New function
- Dayly quizes bulk register.

## Admin user operation using the function
1. login 
2. move to the new screen
3. on the screen check settings
3-1. screen image

 - list of taget challenge category row
 - each row has edit number for create challenge count the row category, 
 - add row, delete row
 - total row see categories, challenges 

3-2. validation when creating a row

 - invalid dupulicate category row
 - invalid callenge count less than 0

4. click [create quiz] button
4-1. api calls and recieves response
4-2. refrect api response to the screen
4-3. check are challenges fine
4-4. if not fine, click [create challenge] button
4-5. if fine, click [save to database] button

5. [save to database] button

 - seve to database these challenges

 
 

