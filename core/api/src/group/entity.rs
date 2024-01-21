use std::collections::HashSet;

use async_graphql::{Enum, InputObject, SimpleObject};

use crate::primitives::*;

#[derive(Debug, Copy, Clone, Eq, PartialEq, Enum, sqlx::Type)]
#[sqlx(type_name = "GrpType", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum GroupType {
    Friends,
    Trip,
    Home,
    Couple,
    Other,
}

#[derive(Debug, InputObject)]
pub struct NewGroup {
    pub name: String,
    #[graphql(name = "type")]
    pub typ: Option<GroupType>,
    /// Group Cover Picture in base64 format
    pub pic: Option<String>,

    pub members: HashSet<UserId>,
}

#[derive(Debug, SimpleObject)]
pub struct Group {
    pub id: GroupId,
    pub name: String,
    #[graphql(name = "type")]
    pub typ: Option<GroupType>,
    /// Group Cover Picture in base64 format
    pub pic: Option<String>,

    pub members: HashSet<UserId>,
}
