import React, { useEffect, useCallback, useRef, useState } from "react";
import f from "lodash/fp";
import _ from "lodash";
import { Icon, Col, Row, Box, Text, Anchor, Rule, Center } from "@tlon/indigo-react";
import moment from "moment";
import { Notifications, Rolodex, Timebox, IndexedNotification, Groups, GroupNotificationsConfig, NotificationGraphConfig } from "~/types";
import { MOMENT_CALENDAR_DATE, daToUnix, resourceAsPath } from "~/logic/lib/util";
import { BigInteger } from "big-integer";
import GlobalApi from "~/logic/api/global";
import { Notification } from "./notification";
import { Associations } from "~/types";
import { cite } from '~/logic/lib/util';
import { InviteItem } from '~/views/components/Invite';
import { useWaitForProps } from "~/logic/lib/useWaitForProps";
import { useHistory } from "react-router-dom";
import {useModal} from "~/logic/lib/useModal";
import {JoinGroup} from "~/views/landscape/components/JoinGroup";
import {Invites} from "./invites";
import {useLazyScroll} from "~/logic/lib/useLazyScroll";

type DatedTimebox = [BigInteger, Timebox];

function filterNotification(associations: Associations, groups: string[]) {
  if (groups.length === 0) {
    return () => true;
  }
  return (n: IndexedNotification) => {
    if ("graph" in n.index) {
      const { group } = n.index.graph;
      return groups.findIndex((g) => group === g) !== -1;
    } else if ("group" in n.index) {
      const { group } = n.index.group;
      return groups.findIndex((g) => group === g) !== -1;
    }
    return true;
  };
}

export default function Inbox(props: {
  notifications: Notifications;
  archive: Notifications;
  groups: Groups;
  showArchive?: boolean;
  api: GlobalApi;
  associations: Associations;
  contacts: Rolodex;
  filter: string[];
  invites: any;
  notificationsGroupConfig: GroupNotificationsConfig;
  notificationsGraphConfig: NotificationGraphConfig;
}) {
  const { api, associations, invites } = props;
  useEffect(() => {
    let seen = false;
    setTimeout(() => {
      seen = true;
    }, 3000);
    return () => {
      if (seen) {
        api.hark.seen();
      }
    };
  }, []);

  const notifications =
    Array.from(props.showArchive ? props.archive : props.notifications) || [];

  const calendar = {
    ...MOMENT_CALENDAR_DATE, sameDay: function (now) {
      if (this.subtract(6, 'hours').isBefore(now)) {
        return "[Earlier Today]";
      } else {
        return MOMENT_CALENDAR_DATE.sameDay;
      }
    }
  };

  let notificationsByDay = f.flow(
    f.map<DatedTimebox, DatedTimebox>(([date, nots]) => [
      date,
      nots.filter(filterNotification(associations, props.filter)),
    ]),
    f.groupBy<DatedTimebox>(([d]) => {
      const date = moment(daToUnix(d));
      if (moment().subtract(6, 'hours').isBefore(date)) {
        return 'latest';
      } else {
        return date.format("YYYYMMDD");
      }
    }),
  )(notifications);

  const notificationsByDayMap = new Map<string, DatedTimebox[]>(
    Object.keys(notificationsByDay).map(timebox => {
      return [timebox, notificationsByDay[timebox]];
    })
  );

  const scrollRef = useRef(null);

  const [joining, setJoining] = useState<[string, string] | null>(null);

  const { modal, showModal } = useModal(
    { modal: useCallback(
      (dismiss) => (
        <JoinGroup
          groups={props.groups}
          contacts={props.contacts}
          api={props.api}
          autojoin={joining?.[0]?.slice(6)}
          inviteUid={joining?.[1]}
        />
        ),
      [props.contacts, props.groups, props.api, joining]
  )})

  const joinGroup = useCallback((group: string, uid: string) => {
    setJoining([group, uid]);
    showModal();
  }, [setJoining, showModal]);

  const acceptInvite = (app: string, uid: string) => async (invite) => {
    const resource = {
      ship: `~${invite.resource.ship}`,
      name: invite.resource.name
    };

    const resourcePath = resourceAsPath(invite.resource);
    if(app === 'contacts') {
      joinGroup(resourcePath, uid);
    } else if ( app === 'chat') {
      await api.invite.accept(app, uid);
      history.push(`/~landscape/home/resource/chat${resourcePath.slice(5)}`);
    } else if ( app === 'graph') {
      await api.invite.accept(app, uid);
      history.push(`/~graph/join${resourcePath}`);
    }
  };




  const inviteItems = (invites, api) => {
    const returned = [];
    Object.keys(invites).map((appKey) => {
      const app = invites[appKey];
      Object.keys(app).map((uid) => {
        const invite = app[uid];
        const inviteItem =
          <InviteItem
            key={uid}
            invite={invite}
            onAccept={acceptInvite(appKey, uid)}
            onDecline={() => api.invite.decline(appKey, uid)}
          />;
        returned.push(inviteItem);
      });
    });
    return returned;
  };

  const loadMore = useCallback(async () => {
    return api.hark.getMore();
  }, [api]);

  const loadedAll = useLazyScroll(scrollRef, 0.2, loadMore);


  return (
    <Col ref={scrollRef} position="relative" height="100%" overflowY="auto">
      {modal}
      <Invites invites={invites} api={api} associations={associations} />
      {[...notificationsByDayMap.keys()].sort().reverse().map((day, index) => {
        const timeboxes = notificationsByDayMap.get(day)!;
        return timeboxes.length > 0 && (
          <DaySection
            key={day}
            label={day === 'latest' ? 'Today' : moment(day).calendar(null, calendar)}
            timeboxes={timeboxes}
            contacts={props.contacts}
            archive={!!props.showArchive}
            associations={props.associations}
            api={api}
            groups={props.groups}
            graphConfig={props.notificationsGraphConfig}
            groupConfig={props.notificationsGroupConfig}
          />
        );
      })}
      {loadedAll && (
        <Center mt="2" borderTop={notifications.length !== 0 ? 1 : 0} borderTopColor="washedGray" width="100%" height="96px">
          <Text gray fontSize="1">No more notifications</Text>
        </Center>
      )}
    </Col>
  );
}

function sortTimeboxes([a]: DatedTimebox, [b]: DatedTimebox) {
  return b.subtract(a);
}

function sortIndexedNotification(
  { notification: a }: IndexedNotification,
  { notification: b }: IndexedNotification
) {
  return b.time - a.time;
}

function DaySection({
  label,
  contacts,
  groups,
  archive,
  timeboxes,
  associations,
  api,
  groupConfig,
  graphConfig,
}) {

  const lent = timeboxes.map(([,nots]) => nots.length).reduce(f.add, 0);
  if (lent === 0 || timeboxes.length === 0) {
    return null;
  }

  return (
    <>
      <Box position="sticky" zIndex={3} top="-1px" bg="white">
        <Box p="2" bg="scales.black05">
          <Text>
            {label}
          </Text>
        </Box>
      </Box>
      {_.map(timeboxes.sort(sortTimeboxes), ([date, nots], i: number) =>
        _.map(nots.sort(sortIndexedNotification), (not, j: number) => (
          <React.Fragment key={j}>
            {(i !== 0 || j !== 0) && (
              <Box flexShrink={0} height="4px" bg="scales.black05" />
            )}
            <Notification
              graphConfig={graphConfig}
              groupConfig={groupConfig}
              api={api}
              associations={associations}
              notification={not}
              archived={archive}
              contacts={contacts}
              groups={groups}
              time={date}
            />
          </React.Fragment>
        ))
      )}
    </>
  );
}
