import React from 'react';
import LevelFeedbackEntry from './LevelFeedbackEntry';

const defaultProps = {
  lessonName: 'Lesson 3: Drawing in Game Lab',
  levelName: '4',
  courseName: 'CSD (18-19)',
  unitName: 'Unit 3 - Animations and Games',
  lastUpdated: '2/5/19 at 4:05pm',
  linkToLevel: '/',
  comments: 'Great job!'
};

export default storybook => {
  return storybook
    .storiesOf('LevelFeedbackEntry', module)
    .withReduxStore()
    .addStoryTable([
      {
        name: 'LevelFeedbackEntry - not yet seen',
        story: () => (
          <LevelFeedbackEntry {...defaultProps} seenByStudent={false} />
        )
      },
      {
        name: 'LevelFeedbackEntry - seen by student',
        story: () => (
          <LevelFeedbackEntry {...defaultProps} seenByStudent={true} />
        )
      }
    ]);
};
