import React, {Component} from 'react';
import ReactDOM from 'react-dom';
import i18n from '@cdo/locale';
import color from '@cdo/apps/util/color';
import shapes from './shapes';
import {UnlocalizedTimeAgo as TimeAgo} from '@cdo/apps/templates/TimeAgo';
import FontAwesome from '@cdo/apps/templates/FontAwesome';

const styles = {
  main: {
    borderWidth: 1,
    borderStyle: 'solid',
    borderColor: color.border_gray,
    minHeight: 72,
    width: '100%',
    marginBottom: 20,
    display: 'flex',
    flexFlow: 'wrap',
    boxSizing: 'border-box'
  },
  lessonDetails: {
    width: '88%',
    marginLeft: 20,
    marginTop: 8,
    marginBottom: 4
  },
  lessonLevel: {
    fontSize: 18,
    lineHeight: '24px',
    marginBottom: 4,
    color: color.teal,
    fontFamily: '"Gotham 5r", sans-serif'
  },
  unit: {
    color: color.dark_charcoal
  },
  time: {
    marginTop: 8,
    fontSize: 14,
    lineHeight: '17px',
    color: color.light_gray,
    float: 'left'
  },
  comment: {
    color: color.dark_charcoal,
    marginLeft: 20,
    marginRight: 20,
    fontSize: 14,
    lineHeight: '21px',
    fontFamily: '"Gotham 5r", sans-serif'
  },
  showMore: {
    color: color.teal,
    cursor: 'pointer',
    fontSize: 14,
    zIndex: 20
  },
  commentBox: {
    float: 'left',
    width: '96%'
  }
};

const measureElement = element => {
  const DOMNode = ReactDOM.findDOMNode(element);
  return {
    height: DOMNode.offsetHeight
  };
};

const initialCommentHeight = 60;

export default class LevelFeedbackEntry extends Component {
  state = {
    expanded: false,
    commentHeight: initialCommentHeight
  };

  static propTypes = {feedback: shapes.feedback};

  expand = () => {
    this.setState({expanded: true});
  };

  collapse = () => {
    this.setState({expanded: false});
  };

  componentDidMount() {
    this.comment &&
      this.setState({commentHeight: measureElement(this.comment).height});
  }

  longComment = () => this.state.commentHeight > initialCommentHeight;

  render() {
    const {
      seen_on_feedback_page_at,
      student_first_visited_at,
      lessonName,
      lessonNum,
      levelNum,
      linkToLevel,
      unitName,
      created_at,
      comment,
      performance
    } = this.props.feedback;

    const seenByStudent = seen_on_feedback_page_at || student_first_visited_at;
    const commentExists = comment.length > 2;
    // These heights ensure that up to two lines of the comment will be visible, and a 'sneak peak' of the third line for long comments.
    const baseHeight = performance && commentExists ? 132 : 112;

    const style = {
      backgroundColor: seenByStudent ? color.background_gray : color.white,
      height: this.state.expanded ? 'auto' : baseHeight,
      overflow: this.state.expanded ? 'none' : 'hidden',
      ...styles.main
    };

    const performanceStyle = {
      width: '100%',
      marginBottom: 5,
      ...styles.comment
    };

    const rubricPerformance = {
      performanceLevel1: i18n.rubricLevelOneHeader(),
      performanceLevel2: i18n.rubricLevelTwoHeader(),
      performanceLevel3: i18n.rubricLevelThreeHeader(),
      performanceLevel4: i18n.rubricLevelFourHeader()
    };

    const rubricText = rubricPerformance[performance];

    const showDownChevron = this.longComment() && !this.state.expanded;
    const showUpChevron = this.longComment() && this.state.expanded;

    return (
      <div
        style={style}
        onClick={this.state.expanded ? this.collapse : this.expand}
      >
        <div style={styles.lessonDetails}>
          <a href={linkToLevel}>
            <div style={styles.lessonLevel}>
              {i18n.feedbackNotificationLesson({
                lessonNum,
                lessonName,
                levelNum
              })}
            </div>
          </a>
          <div style={styles.unit}>
            {i18n.feedbackNotificationUnit({unitName})}
          </div>
        </div>
        <TimeAgo style={styles.time} dateString={created_at} />
        {performance && (
          <div style={performanceStyle}>
            {i18n.feedbackRubricEvaluation({rubricText})}
          </div>
        )}
        {commentExists && (
          <span style={styles.commentBox}>
            <div ref={r => (this.comment = r)} style={styles.comment}>
              &quot;{comment}&quot;
            </div>
          </span>
        )}
        {showDownChevron ? (
          <span style={styles.showMore}>
            {i18n.feedbackShowMore()} <FontAwesome icon="chevron-down" />
          </span>
        ) : null}
        {showUpChevron ? (
          <span style={styles.showMore}>
            {i18n.feedbackShowMore()} <FontAwesome icon="chevron-up" />
          </span>
        ) : null}
      </div>
    );
  }
}
