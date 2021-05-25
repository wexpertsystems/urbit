import { Box, Col, Text } from '@tlon/indigo-react';
import { GraphNode } from '@urbit/api';
import bigInt from 'big-integer';
import React from 'react';
import { resourceFromPath } from '~/logic/lib/group';
import { useGraph } from '~/logic/state/graph';
import { Loading } from '~/views/components/Loading';
import PostFeed from './PostFeed';
import PostItem from './PostItem/PostItem';
import { stringToArr } from '~/views/components/ArrayVirtualScroller';


export default function PostReplies(props) {
  const {
    baseUrl,
    api,
    history,
    association,
    graphPath,
    group,
    vip,
    pendingSize
  } = props;

  const graphRid = resourceFromPath(graphPath);
  let graph = useGraph(graphRid.ship, graphRid.name);

  const shouldRenderFeed = Boolean(graph);

  if (!shouldRenderFeed) {
    return (
      <Box height="100%" width="100%" alignItems="center" pl={1} pt={3}>
        <Loading />
      </Box>
    );
  }

  const locationUrl =
    props.locationUrl.replace(`${baseUrl}/feed/replies`, '');
  const nodeIndex = stringToArr(locationUrl);

  let node: GraphNode;
  let parentNode;
  nodeIndex.forEach((i, idx) => {
    if (!graph) {
      return null;
    }
    node = graph.get(i);
    if(idx < nodeIndex.length - 1) {
      parentNode = node;
    }
    if (!node) {
      return null;
    }
    graph = node.children;
  });

  if (!node || !graph) {
    return null;
  }

  const first = graph.peekLargest()?.[0];
  if (!first) {
    return (
      <Col
        key={`/replies/${locationUrl}`}
        width="100%"
        height="100%"
        alignItems="center" overflowY="scroll"
      >
        <Box mt={3} width="100%" alignItems="center">
          <PostItem
            key={node.post.index}
            node={node}
            graphPath={graphPath}
            association={association}
            api={api}
            index={nodeIndex}
            baseUrl={baseUrl}
            history={history}
            isParent={true}
            parentPost={parentNode?.post}
            vip={vip}
            group={group}
          />
        </Box>
        <Box
          pl={2}
          pr={2}
          width="100%"
          maxWidth="616px"
          alignItems="center"
        >
          <Col bg="washedGray" width="100%" alignItems="center" p={3}>
            <Text textAlign="center" width="100%">
              No one has posted any replies yet.
            </Text>
          </Col>
        </Box>
      </Col>
    );
  }

  return (
    <Box height="calc(100% - 48px)" width="100%" alignItems="center" pl={1} pt={3}>
      <PostFeed
        key={`/replies/${locationUrl}`}
        graphPath={graphPath}
        graph={graph}
        grandparentNode={parentNode}
        parentNode={node}
        pendingSize={pendingSize}
        association={association}
        group={group}
        vip={vip}
        api={api}
        history={history}
        baseUrl={baseUrl}
      />
    </Box>
  );
}

