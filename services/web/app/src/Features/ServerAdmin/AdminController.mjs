import logger from '@overleaf/logger'
import http from 'node:http'
import https from 'node:https'
import Settings from '@overleaf/settings'
import TpdsUpdateSender from '../ThirdPartyDataStore/TpdsUpdateSender.mjs'
import TpdsProjectFlusher from '../ThirdPartyDataStore/TpdsProjectFlusher.mjs'
import EditorRealTimeController from '../Editor/EditorRealTimeController.mjs'
import SystemMessageManager from '../SystemMessages/SystemMessageManager.mjs'
import ProjectGetter from '../Project/ProjectGetter.mjs'
import { User } from '../../models/User.mjs'
import UserSessionsManager from '../User/UserSessionsManager.mjs'
import Modules from '../../infrastructure/Modules.mjs'
import Features from '../../infrastructure/Features.mjs'
import { expressify } from '@overleaf/promise-utils'

const AdminController = {
  _sendDisconnectAllUsersMessage: delay => {
    return EditorRealTimeController.emitToAll(
      'forceDisconnect',
      'Sorry, we are performing a quick update to the editor and need to close it down. Please refresh the page to continue.',
      delay
    )
  },
  index: expressify(async (req, res, next) => {
    let url
    const openSockets = {}
    for (url in http.globalAgent.sockets) {
      openSockets[`http://${url}`] = http.globalAgent.sockets[url].map(
        socket => socket._httpMessage.path
      )
    }

    for (url in https.globalAgent.sockets) {
      openSockets[`https://${url}`] = https.globalAgent.sockets[url].map(
        socket => socket._httpMessage.path
      )
    }

    const systemMessages =
      await SystemMessageManager.promises.getMessagesFromDB()

    const privilegesMatrixResults = await Modules.promises.hooks.fire(
      'getPrivilegesMatrix'
    )

    const privilegesMatrix = privilegesMatrixResults[0] || null

    let users = []
    try {
      users = await User.find(
        {},
        'email first_name last_name isAdmin signUpDate lastLoggedIn deactivated loginCount'
      )
        .sort({ signUpDate: -1 })
        .lean()
    } catch (err) {
      logger.error({ err }, 'failed to fetch users for admin panel')
    }

    const toRender = {
      title: 'System Admin',
      openSockets,
      systemMessages,
      privilegesMatrix,
      users,
      currentUser: req.session?.passport?.user || req.session?.user,
    }

    if (Features.hasFeature('saas')) {
      const debugProjects = await ProjectGetter.promises.findAllDebugProjects(
        'name lastUpdated owner_ref'
      )
      toRender.debugProjects = debugProjects
    }
    res.render('admin/index', toRender)
  }),

  disconnectAllUsers: (req, res) => {
    logger.warn('disconecting everyone')
    const delay = (req.query && req.query.delay) > 0 ? req.query.delay : 10
    AdminController._sendDisconnectAllUsersMessage(delay)
    res.redirect('/admin#open-close-editor')
  },

  openEditor(req, res) {
    logger.warn('opening editor')
    Settings.editorIsOpen = true
    res.redirect('/admin#open-close-editor')
  },

  closeEditor(req, res) {
    logger.warn('closing editor')
    Settings.editorIsOpen = req.body.isOpen
    res.redirect('/admin#open-close-editor')
  },

  flushProjectToTpds(req, res, next) {
    TpdsProjectFlusher.flushProjectToTpds(req.body.project_id, error => {
      if (error) {
        return next(error)
      }
      res.sendStatus(200)
    })
  },

  pollDropboxForUser(req, res) {
    const { user_id: userId } = req.body
    TpdsUpdateSender.pollDropboxForUser(userId, () => res.sendStatus(200))
  },

  createMessage(req, res, next) {
    SystemMessageManager.createMessage(req.body.content, function (error) {
      if (error) {
        return next(error)
      }
      res.redirect('/admin#system-messages')
    })
  },

  clearMessages(req, res, next) {
    SystemMessageManager.clearMessages(function (error) {
      if (error) {
        return next(error)
      }
      res.redirect('/admin#system-messages')
    })
  },

  toggleUserStatus: expressify(async (req, res, next) => {
    const targetUserId = req.params.user_id
    const currentUserId = (
      req.session?.passport?.user?._id || req.session?.user?._id
    )?.toString()

    if (targetUserId === currentUserId) {
      logger.warn({ targetUserId }, 'admin attempted to toggle own status')
      return res
        .status(400)
        .send('No puedes desactivar tu propia cuenta de administrador.')
    }

    const targetUser = await User.findById(targetUserId).exec()
    if (!targetUser) {
      return res.status(404).send('Usuario no encontrado')
    }

    const newStatus = !targetUser.deactivated
    targetUser.deactivated = newStatus
    if (newStatus) {
      targetUser.deactivatedAt = new Date()
      targetUser.deactivatedBy = currentUserId
    } else {
      targetUser.deactivatedAt = undefined
      targetUser.deactivatedBy = undefined
    }

    await targetUser.save()
    logger.info(
      { targetUserId, newStatus, currentUserId },
      'toggled user deactivation status'
    )

    if (newStatus) {
      try {
        await UserSessionsManager.promises.removeSessionsFromRedis(targetUser)
      } catch (err) {
        logger.error(
          { err, targetUserId },
          'failed to remove sessions for deactivated user'
        )
      }
    }

    res.redirect('/admin#user-management')
  }),
}

export default AdminController
