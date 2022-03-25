use std::{
    fmt::{Display, Write},
    io,
};

use anyhow::Context;
use i3_ipc::{
    event::{Event, Subscribe, WindowChange, WindowData},
    reply::{Node, NodeLayout, NodeType},
    Connect,
    I3Stream,
    I3,
};
use tracing::{debug, error, info, trace, warn, Level};

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .compact()
        .with_max_level(if cfg!(debug_assertions) {
            Level::TRACE
        } else {
            Level::INFO
        })
        .init();

    // need 2 connections as the library panics if one is used for events and
    // getting the tree
    let mut listener_i3 = I3Stream::conn_sub([Subscribe::Window])?;
    let mut i3 = I3::connect()?;

    info!("Listener started");

    for ev in listener_i3.listen() {
        let ev = ev?;
        if let Event::Window(ev) = ev {
            if let Err(e) = handle_window_event(&mut i3, &ev) {
                error!("Error in window event handler: {}", e);
            }
        }
    }

    Ok(())
}

enum SplitLayout {
    H,
    V,
}

impl Display for SplitLayout {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_char(match self {
            SplitLayout::H => 'h',
            SplitLayout::V => 'v',
        })
    }
}

fn handle_window_event(i3: &mut I3Stream, ev: &WindowData) -> anyhow::Result<()> {
    if ev.change != WindowChange::New {
        return Ok(());
    }

    info!("Window added with id {}", ev.container.id);

    let tree = i3.get_tree()?;

    let parent = find_parent(&tree, ev.container.id);

    if parent.is_none() {
        warn!("Node has no parent!");
        return Ok(());
    }

    let parent = parent.unwrap();

    trace!("Got parent");

    if parent.node_type == NodeType::Workspace && parent.nodes.len() < 3 {
        warn!("Skipping split that would just turn around windows");
        return Ok(());
    }

    let new_split_layout = match parent.layout {
        // opposite of parent layout
        NodeLayout::SplitH => SplitLayout::V,
        NodeLayout::SplitV => SplitLayout::H,
        _ => {
            debug!("Ignoring new window create in non-split container");
            return Ok(());
        },
    };

    let new_win_index_in_parent = parent
        .nodes
        .iter()
        .enumerate()
        .find(|(_i, node)| node.id == ev.container.id)
        .context("Node not in parent?!")?
        .0;

    if new_win_index_in_parent == 0 {
        warn!("New window is only window in parent, ignoring");
        return Ok(());
    }

    let prev = &parent.nodes[new_win_index_in_parent - 1];
    let move_direction = match new_split_layout {
        SplitLayout::H => "up",
        SplitLayout::V => "left",
    };

    trace!(
        "Previous is {:?}, new is {:?}",
        &prev.name,
        ev.container.name
    );

    // split previous window
    log_command(
        i3,
        &format!(r#"[con_id="{}"] split {}"#, prev.id, new_split_layout),
    )?;
    // move new window into split
    log_command(
        i3,
        &format!(r#"[con_id="{}"] move {}"#, ev.container.id, move_direction),
    )?;

    Ok(())
}

fn log_command(i3: &mut I3Stream, cmd: &str) -> io::Result<()> {
    debug!("Running command `{}`", cmd);
    i3.run_command(cmd)?;
    Ok(())
}

fn find_parent(node: &Node, id: usize) -> Option<&Node> {
    if node.nodes.iter().any(|n| n.id == id) {
        return Some(node);
    }

    for n in &node.nodes {
        if let Some(n) = find_parent(n, id) {
            return Some(n);
        }
    }

    None
}
