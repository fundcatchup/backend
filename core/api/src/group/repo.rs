use sqlx::{Pool, Postgres};
use uuid::Uuid;

use super::entity::*;
use crate::primitives::*;

#[derive(Debug, Clone)]
pub struct Groups {
    pool: Pool<Postgres>,
}

impl Groups {
    pub fn new(pool: Pool<Postgres>) -> Self {
        Self { pool }
    }

    pub async fn create(&self, new_group: NewGroup) -> anyhow::Result<Group> {
        let NewGroup {
            name,
            typ,
            pic,
            members,
        } = new_group;

        let mut tx = self.pool.begin().await?;

        let row = sqlx::query!(
            r#"
            INSERT INTO Grp(name, type, picture)
            VALUES ($1, $2, $3)
            RETURNING id;
            "#,
            name,
            typ as Option<GroupType>,
            pic
        )
        .fetch_one(&mut *tx)
        .await?;

        let grp_id = GroupId::from(row.id);
        let member_ids: Vec<Uuid> = members
            .clone()
            .into_iter()
            .map(|user_id| user_id.into())
            .collect();

        sqlx::query!(
            r#"
            INSERT INTO GrpMembers(grp_id, uid)
            SELECT $1, UNNEST($2::UUID[])
            "#,
            Uuid::from(grp_id),
            &member_ids
        )
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;

        Ok(Group {
            id: grp_id,
            name,
            typ,
            pic,
            members,
        })
    }
}
