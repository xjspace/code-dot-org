/** @file Top-level view for GameLab */
/* global dashboard */
import classNames from 'classnames';
import {connect} from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import AnimationTab from './AnimationTab/AnimationTab';
import StudioAppWrapper from '@cdo/apps/templates/StudioAppWrapper';
import ErrorDialogStack from './ErrorDialogStack';
import AnimationJsonViewer from './AnimationJsonViewer';
import {P5LabInterfaceMode, APP_WIDTH, APP_HEIGHT} from './constants';
import GameLabVisualizationHeader from './GameLabVisualizationHeader';
import GameLabVisualizationColumn from './GameLabVisualizationColumn';
import InstructionsWithWorkspace from '@cdo/apps/templates/instructions/InstructionsWithWorkspace';
import {isResponsiveFromState} from '@cdo/apps/templates/ProtectedVisualizationDiv';
import CodeWorkspace from '@cdo/apps/templates/CodeWorkspace';
import {allowAnimationMode, showVisualizationHeader} from './stateQueries';
import IFrameEmbedOverlay from '@cdo/apps/templates/IFrameEmbedOverlay';
import VisualizationResizeBar from '@cdo/apps/lib/ui/VisualizationResizeBar';
import AnimationPicker from './AnimationPicker/AnimationPicker';

/**
 * Top-level React wrapper for GameLab
 */
class GameLabView extends React.Component {
  static propTypes = {
    // Provided manually
    showFinishButton: PropTypes.bool.isRequired,
    onMount: PropTypes.func.isRequired,
    // Provided by Redux
    interfaceMode: PropTypes.oneOf([
      P5LabInterfaceMode.CODE,
      P5LabInterfaceMode.ANIMATION
    ]).isRequired,
    isResponsive: PropTypes.bool.isRequired,
    hideSource: PropTypes.bool.isRequired,
    pinWorkspaceToBottom: PropTypes.bool.isRequired,
    allowAnimationMode: PropTypes.bool.isRequired,
    showVisualizationHeader: PropTypes.bool.isRequired,
    isIframeEmbed: PropTypes.bool.isRequired,
    isRunning: PropTypes.bool.isRequired,
    spriteLab: PropTypes.bool.isRequired
  };

  getChannelId() {
    if (dashboard && dashboard.project) {
      return dashboard.project.getCurrentId();
    }
    return undefined;
  }

  componentDidMount() {
    this.props.onMount();
  }

  renderCodeMode() {
    const {
      interfaceMode,
      isResponsive,
      hideSource,
      pinWorkspaceToBottom,
      showFinishButton
    } = this.props;

    // Code mode contains protected (non-React) content.  We have to always
    // render it, so when we're not in code mode use CSS to hide it.
    const codeModeStyle = {
      display: interfaceMode !== P5LabInterfaceMode.CODE ? 'none' : undefined
    };

    const visualizationColumnStyle = {
      width: APP_WIDTH
    };

    const visualizationColumnClassNames = classNames({
      responsive: isResponsive,
      pin_bottom: !hideSource && pinWorkspaceToBottom
    });

    return (
      <div style={codeModeStyle}>
        <div
          id="visualizationColumn"
          className={visualizationColumnClassNames}
          style={visualizationColumnStyle}
        >
          {this.props.showVisualizationHeader && <GameLabVisualizationHeader />}
          <GameLabVisualizationColumn finishButton={showFinishButton} />
          {this.getChannelId() && (
            <AnimationPicker
              channelId={this.getChannelId()}
              allowedExtensions=".png,.jpg,.jpeg"
            />
          )}
        </div>
        {this.props.isIframeEmbed && !this.props.isRunning && (
          <IFrameEmbedOverlay
            appWidth={APP_WIDTH}
            appHeight={APP_HEIGHT}
            style={{top: 79, left: 17}}
            playButtonStyle={{top: 620, left: 179}}
          />
        )}
        <VisualizationResizeBar />
        <InstructionsWithWorkspace>
          <CodeWorkspace withSettingsCog={!this.props.spriteLab} />
        </InstructionsWithWorkspace>
      </div>
    );
  }

  renderAnimationMode() {
    const {allowAnimationMode, interfaceMode} = this.props;
    return allowAnimationMode &&
      interfaceMode === P5LabInterfaceMode.ANIMATION ? (
      <AnimationTab channelId={this.getChannelId()} />
    ) : (
      undefined
    );
  }

  render() {
    return (
      <StudioAppWrapper>
        {this.renderCodeMode()}
        {this.renderAnimationMode()}
        <ErrorDialogStack />
        <AnimationJsonViewer />
      </StudioAppWrapper>
    );
  }
}
export default connect(state => ({
  hideSource: state.pageConstants.hideSource,
  interfaceMode: state.interfaceMode,
  isResponsive: isResponsiveFromState(state),
  pinWorkspaceToBottom: state.pageConstants.pinWorkspaceToBottom,
  allowAnimationMode: allowAnimationMode(state),
  showVisualizationHeader: showVisualizationHeader(state),
  isRunning: state.runState.isRunning,
  isIframeEmbed: state.pageConstants.isIframeEmbed,
  spriteLab: state.pageConstants.isBlockly
}))(GameLabView);
